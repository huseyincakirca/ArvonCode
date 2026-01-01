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
        public string $createdAt
    ) {
    }

    public function backoff(): array
    {
        return [10, 30, 120];
    }

    public function handle(PushNotificationService $pushNotificationService): void
    {
        $tokens = UserPushToken::query()
            ->where('user_id', $this->ownerId)
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

        $pushNotificationService->sendToTokens(
            $tokens,
            $this->type,
            $this->vehicleUuid,
            $this->createdAt
        );
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
}
