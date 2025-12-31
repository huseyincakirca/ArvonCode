<?php

namespace App\Listeners;

use App\Events\OwnerNotifiableEvent;
use App\Models\UserPushToken;
use App\Services\Push\PushNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendOwnerPushNotification implements ShouldQueue
{
    use InteractsWithQueue;

    public function __construct(private PushNotificationService $pushNotificationService)
    {
    }

    public function handle(OwnerNotifiableEvent $event): void
    {
        $tokens = UserPushToken::query()
            ->where('user_id', $event->ownerId)
            ->pluck('token')
            ->all();

        foreach ($tokens as $token) {
            try {
                $this->pushNotificationService->sendToToken(
                    $token,
                    $event->type,
                    $event->vehicleId,
                    $event->createdAt
                );
            } catch (\Throwable $e) {
                Log::error('Failed to send push notification to owner', [
                    'user_id' => $event->ownerId,
                    'vehicle_id' => $event->vehicleId,
                    'type' => $event->type,
                    'token' => $token,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }
}
