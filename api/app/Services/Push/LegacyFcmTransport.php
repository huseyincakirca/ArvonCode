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
        $result = $this->sendAndClassify($token, $notification, $data);

        if ($result['status'] === 'retryable') {
            throw new RuntimeException('Legacy FCM retryable error for token: ' . $token);
        }
    }

    public function sendMulticast(array $tokens, array $notification, array $data): array
    {
        $results = [
            'success' => [],
            'invalid' => [],
            'retryable' => [],
        ];

        foreach ($tokens as $token) {
            $result = $this->sendAndClassify($token, $notification, $data);

            $results[$result['status']][] = $token;
        }

        Log::info('Legacy FCM multicast batch processed', [
            'transport' => 'legacy',
            'batch_size' => count($tokens),
            'success_count' => count($results['success']),
            'invalid_count' => count($results['invalid']),
            'retry_count' => count($results['retryable']),
        ]);

        return $results;
    }

    private function sendAndClassify(string $token, array $notification, array $data): array
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
            return [
                'status' => 'invalid',
            ];
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

            return [
                'status' => 'retryable',
            ];
        }

        if ($response->clientError()) {
            Log::warning('FCM push skipped due to client error', array_merge($context, [
                'status' => $response->status(),
                'body' => $response->body(),
            ]));

            return [
                'status' => 'invalid',
            ];
        }

        if ($response->failed()) {
            Log::error('FCM push send failed with unexpected error', array_merge($context, [
                'status' => $response->status(),
                'body' => $response->body(),
            ]));

            return [
                'status' => 'retryable',
            ];
        }

        Log::info('FCM push sent', array_merge($context, [
            'note' => 'Using FCM legacy HTTP API',
        ]));

        return [
            'status' => 'success',
        ];
    }
}
