<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    private const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

    public function sendToToken(string $token, string $type, int $vehicleId, string $createdAt): void
    {
        $serverKey = env('FCM_SERVER_KEY');

        if (empty($serverKey)) {
            Log::warning('FCM_SERVER_KEY is not set; skipping push notification.', [
                'token' => $token,
                'type' => $type,
                'vehicle_id' => $vehicleId,
            ]);
            return;
        }

        $payload = [
            'to' => $token,
            'notification' => [
                'title' => $type === 'location' ? 'New location received' : 'New message received',
                'body' => 'Tap to view details',
            ],
            'data' => [
                'type' => $type,
                'vehicle_id' => $vehicleId,
                'created_at' => $createdAt,
            ],
        ];

        $response = Http::withHeaders([
            'Authorization' => 'key=' . $serverKey,
            'Content-Type' => 'application/json',
        ])->post(self::FCM_ENDPOINT, $payload);

        if ($response->failed()) {
            Log::error('FCM push send failed', [
                'status' => $response->status(),
                'body' => $response->body(),
                'token' => $token,
                'type' => $type,
                'vehicle_id' => $vehicleId,
            ]);
            $response->throw();
        }
    }
}
