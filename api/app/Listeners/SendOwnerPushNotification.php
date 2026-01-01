<?php

namespace App\Listeners;

use App\Events\OwnerNotifiableEvent;
use App\Jobs\SendPushNotificationJob;
use App\Models\UserPushToken;
use App\Models\Vehicle;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SendOwnerPushNotification
{
    public function handle(OwnerNotifiableEvent $event): void
    {
        $vehicleId = Vehicle::query()
            ->where('vehicle_id', $event->vehicleUuid)
            ->value('id');

        $lockKey = sprintf('push_lock:%s:%s', $vehicleId ?? $event->vehicleUuid, $event->type);
        $lock = Cache::lock($lockKey, 10);

        if (!$lock->get()) {
            Log::info('Push dispatch skipped due to active flood lock', [
                'owner_id' => $event->ownerId,
                'vehicle_uuid' => $event->vehicleUuid,
                'type' => $event->type,
            ]);
            return;
        }

        $hasTokens = UserPushToken::query()
            ->where('user_id', $event->ownerId)
            ->exists();

        if (!$hasTokens) {
            Log::info('Push dispatch skipped; no push tokens for owner', [
                'owner_id' => $event->ownerId,
                'vehicle_uuid' => $event->vehicleUuid,
                'type' => $event->type,
            ]);
            $lock->release();
            return;
        }

        SendPushNotificationJob::dispatch(
            $event->ownerId,
            $event->type,
            $event->vehicleUuid,
            $event->createdAt
        );
        // lock intentionally left to expire (TTL 10s) to prevent flood
    }
}
