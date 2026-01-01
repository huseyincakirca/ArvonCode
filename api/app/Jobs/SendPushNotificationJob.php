<?php

namespace App\Jobs;

use App\Models\UserPushToken;
use App\Services\Push\PushNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;

    public function __construct(
        public int $ownerId,
        public string $type,
        public string $vehicleUuid,
        public string $createdAt,
        public ?array $tokens = null
    ) {
    }

    public function backoff(): array
    {
        return [10, 30, 120];
    }

    public function handle(PushNotificationService $pushNotificationService): void
    {
        $tokens = $this->tokens ?? UserPushToken::query()
            ->where('user_id', $this->ownerId)
            ->where(function ($query) {
                $query->whereNull('is_active')
                    ->orWhere('is_active', true);
            })
            ->pluck('token')
            ->all();

        if (empty($tokens)) {
            Log::info('No push tokens found for owner; skipping push dispatch', [
                'owner_id' => $this->ownerId,
                'vehicle_uuid' => $this->vehicleUuid,
                'type' => $this->type,
            ]);
            return;
        }

        $results = $pushNotificationService->sendToTokens(
            $tokens,
            $this->type,
            $this->vehicleUuid,
            $this->createdAt
        );

        $this->handleResults($results);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('SendPushNotificationJob failed', [
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'type' => $this->type,
            'error' => $exception->getMessage(),
        ]);
    }

    private function handleResults(array $results): void
    {
        $success = $results['success'] ?? [];
        $invalid = $results['invalid'] ?? [];
        $retryable = $results['retryable'] ?? [];

        Log::info('Push multicast batch processed', [
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'type' => $this->type,
            'batch_size' => count($success) + count($invalid) + count($retryable),
            'success_count' => count($success),
            'invalid_count' => count($invalid),
            'retry_count' => count($retryable),
        ]);

        if (!empty($invalid)) {
            $this->invalidateTokens($invalid);
        }

        if (!empty($retryable) && $this->shouldRetrySubset()) {
            $this->retrySubset($retryable);
        }
    }

    private function invalidateTokens(array $tokens): void
    {
        $hashed = array_map(fn ($token) => hash('sha256', $token), $tokens);

        UserPushToken::query()
            ->whereIn('token', $tokens)
            ->update([
                'is_active' => false,
            ]);

        UserPushToken::query()
            ->whereIn('token', $tokens)
            ->delete();

        Log::warning('Invalid push tokens soft-disabled', [
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'type' => $this->type,
            'token_hashes' => $hashed,
        ]);
    }

    private function shouldRetrySubset(): bool
    {
        return method_exists($this, 'attempts')
            ? $this->attempts() < $this->tries
            : true;
    }

    private function retrySubset(array $tokens): void
    {
        $uniqueTokens = array_values(array_unique($tokens));

        Log::info('Dispatching retry for retryable push tokens', [
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'type' => $this->type,
            'retry_count' => count($uniqueTokens),
        ]);

        self::dispatch(
            $this->ownerId,
            $this->type,
            $this->vehicleUuid,
            $this->createdAt,
            $uniqueTokens
        )->delay(now()->addSeconds($this->backoff()[0] ?? 10));
    }
}
