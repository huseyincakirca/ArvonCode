<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class LegacyFcmTransport implements PushTransportInterface
{
    private const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

    public function send(string $token, array $notification, array $data, array $context = []): void
    {
        $result = $this->sendAndClassify($token, $notification, $data, $context);

        if ($result['status'] === 'retryable') {
            throw new RuntimeException('Legacy FCM retryable error for token: ' . $token);
        }
    }

    public function sendMulticast(array $tokens, array $notification, array $data, array $context = []): array
    {
        $results = [
            'success' => [],
            'invalid' => [],
            'retryable' => [],
        ];

        $baseContext = array_merge([
            'type' => $data['type'] ?? null,
            'vehicle_uuid' => $data['vehicle_uuid'] ?? null,
            'transport' => 'legacy',
            'transport_config_key' => 'services.fcm.transport',
            'transport_config_value' => config('services.fcm.transport'),
            'token_count' => count($tokens),
            'exception_class' => null,
            'exception_message' => null,
        ], $context);

        foreach ($tokens as $token) {
            $result = $this->sendAndClassify($token, $notification, $data, array_merge($baseContext, [
                'token' => $token,
                'token_count' => 1,
            ]));

            $results[$result['status']][] = $token;
        }

        Log::info('push_sent', array_merge($baseContext, [
            'success_count' => count($results['success']),
            'invalid_count' => count($results['invalid']),
            'retryable_count' => count($results['retryable']),
        ]));

        return $results;
    }

    private function sendAndClassify(string $token, array $notification, array $data, array $context = []): array
    {
        $serverKey = config('services.fcm.server_key');
        $context = array_merge([
            'token' => $token,
            'type' => $data['type'] ?? null,
            'vehicle_uuid' => $data['vehicle_uuid'] ?? null,
            'transport' => 'legacy',
            'transport_config_key' => 'services.fcm.transport',
            'transport_config_value' => config('services.fcm.transport'),
        ], $context);

        if (empty($serverKey)) {
            Log::error('push_failed', array_merge($context, [
                'reason' => 'server_key_missing',
                'exception_message' => 'FCM_SERVER_KEY is not set; skipping push notification.',
            ]));
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
            Log::error('push_failed', array_merge($context, [
                'http_status' => $response->status(),
                'exception_message' => 'Legacy FCM server error',
                'body' => $response->body(),
            ]));

            return [
                'status' => 'retryable',
            ];
        }

        if ($response->clientError()) {
            Log::error('push_failed', array_merge($context, [
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error'),
                'exception_message' => 'Legacy FCM client error',
                'body' => $response->body(),
            ]));

            return [
                'status' => 'invalid',
            ];
        }

        if ($response->failed()) {
            Log::error('push_failed', array_merge($context, [
                'http_status' => $response->status(),
                'exception_message' => 'Legacy FCM unexpected failure',
                'body' => $response->body(),
            ]));

            return [
                'status' => 'retryable',
            ];
        }

        Log::info('push_sent', array_merge($context, [
            'http_status' => $response->status(),
        ]));

        return [
            'status' => 'success',
        ];
    }
}
