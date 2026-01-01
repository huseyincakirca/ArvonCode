<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class LegacyFcmTransport implements PushTransportInterface
{
    private const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

    public function send(string $token, array $notification, array $data): void
    {
        $serverKey = config('services.fcm.server_key');
        $context = [
            'token' => $token,
            'type' => $data['type'] ?? null,
            'vehicle_uuid' => $data['vehicle_uuid'] ?? null,
        ];

        if (empty($serverKey)) {
            Log::warning('FCM_SERVER_KEY is not set; skipping push notification.', [
                ...$context,
            ]);
            return;
        }

        $response = Http::withHeaders([
            'Authorization' => 'key=' . $serverKey,
            'Content-Type' => 'application/json',
        ])
            ->timeout(10)
            ->post(self::FCM_ENDPOINT, [
                'to' => $token,
                'notification' => $notification,
                'data' => $data,
            ]);

        if ($response->serverError()) {
            Log::error('FCM push send failed with server error', array_merge($context, [
                'status' => $response->status(),
                'body' => $response->body(),
            ]));

            throw new RuntimeException('FCM server error: ' . $response->status());
        }

        if ($response->clientError()) {
            Log::warning('FCM push skipped due to client error', array_merge($context, [
                'status' => $response->status(),
                'body' => $response->body(),
            ]));

            return;
        }

        if ($response->failed()) {
            Log::error('FCM push send failed with unexpected error', array_merge($context, [
                'status' => $response->status(),
                'body' => $response->body(),
            ]));

            $response->throw();
        }

        Log::info('FCM push sent', array_merge($context, [
            'note' => 'Using FCM legacy HTTP API',
        ]));
    }
}
