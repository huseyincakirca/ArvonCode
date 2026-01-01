<?php

namespace App\Jobs;

use App\Models\UserPushToken;
use App\Models\Vehicle;
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
    private ?int $vehicleIdCache = null;

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
        $vehicleId = $this->resolveVehicleId();
        $tokens = $this->tokens ?? UserPushToken::query()
            ->where('user_id', $this->ownerId)
            ->where(function ($query) {
                $query->whereNull('is_active')
                    ->orWhere('is_active', true);
            })
            ->pluck('token')
            ->all();

        $jobContext = $this->buildJobContext([
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'vehicle_id' => $vehicleId,
            'type' => $this->type,
        ]);

        if (empty($tokens)) {
            Log::info('No push tokens found for owner; skipping push dispatch', $jobContext);
            return;
        }

        $results = $pushNotificationService->sendToTokens(
            $tokens,
            $this->type,
            $this->vehicleUuid,
            $this->createdAt,
            array_merge($jobContext, [
                'queue' => $jobContext['queue'] ?? null,
                'connection' => $jobContext['connection'] ?? null,
                'attempts' => $jobContext['attempts'] ?? null,
                'max_tries' => $jobContext['max_tries'] ?? null,
                'token_count' => count($tokens),
            ])
        );

        $this->handleResults($results, $jobContext, $pushNotificationService);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('push_dispatch_failed', array_merge($this->buildJobContext([
            'owner_id' => $this->ownerId,
            'vehicle_uuid' => $this->vehicleUuid,
            'vehicle_id' => $this->resolveVehicleId(),
            'type' => $this->type,
            'transport_config_key' => 'services.fcm.transport',
            'transport_config_value' => config('services.fcm.transport'),
            'transport' => config('services.fcm.transport') === 'v1' ? 'fcm_http_v1' : 'legacy',
        ]), [
            'exception_class' => get_class($exception),
            'exception_message' => $exception->getMessage(),
        ]));
    }

    private function handleResults(array $results, array $jobContext, PushNotificationService $pushNotificationService): void
    {
        $success = $results['success'] ?? [];
        $invalid = $results['invalid'] ?? [];
        $retryable = $results['retryable'] ?? [];

        $transportContext = $pushNotificationService->getTransportContext();
        $tokenCount = count($success) + count($invalid) + count($retryable);

        Log::info('push_sent', array_merge($transportContext, $jobContext, [
            'token_count' => $tokenCount,
            'success_count' => count($success),
            'invalid_count' => count($invalid),
            'retryable_count' => count($retryable),
        ]));

        if (!empty($invalid)) {
            $this->invalidateTokens($invalid, array_merge($transportContext, $jobContext, [
                'invalid_count' => count($invalid),
            ]));
        }

        if (!empty($retryable) && $this->shouldRetrySubset()) {
            $this->retrySubset($retryable, array_merge($transportContext, $jobContext, [
                'retryable_count' => count($retryable),
            ]));
        }
    }

    private function invalidateTokens(array $tokens, array $context): void
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

        Log::warning('push_token_invalidated', array_merge($context, [
            'token_hashes' => $hashed,
            'exception_class' => $context['exception_class'] ?? null,
            'exception_message' => $context['exception_message'] ?? 'invalid_tokens_soft_disabled',
        ]));
    }

    private function shouldRetrySubset(): bool
    {
        return method_exists($this, 'attempts')
            ? $this->attempts() < $this->tries
            : true;
    }

    private function retrySubset(array $tokens, array $context): void
    {
        $uniqueTokens = array_values(array_unique($tokens));

        Log::info('Dispatching retry for retryable push tokens', array_merge($context, [
            'retry_count' => count($uniqueTokens),
        ]));

        self::dispatch(
            $this->ownerId,
            $this->type,
            $this->vehicleUuid,
            $this->createdAt,
            $uniqueTokens
        )->delay(now()->addSeconds($this->backoff()[0] ?? 10));
    }

    private function buildJobContext(array $context = []): array
    {
        return array_merge([
            'job_class' => self::class,
            'queue' => $this->queue ?? null,
            'connection' => $this->connection ?? null,
            'attempts' => method_exists($this, 'attempts') ? $this->attempts() : null,
            'max_tries' => $this->tries ?? null,
            'exception_class' => null,
            'exception_message' => null,
        ], $context);
    }

    private function resolveVehicleId(): ?int
    {
        if ($this->vehicleIdCache !== null) {
            return $this->vehicleIdCache;
        }

        $this->vehicleIdCache = Vehicle::query()
            ->where('vehicle_id', $this->vehicleUuid)
            ->value('id');

        return $this->vehicleIdCache;
    }
}
