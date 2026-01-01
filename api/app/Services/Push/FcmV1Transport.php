<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FcmV1Transport implements PushTransportInterface
{
    private const OAUTH_TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
    private const FCM_ENDPOINT_TEMPLATE = 'https://fcm.googleapis.com/v1/projects/%s/messages:send';
    private const OAUTH_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function __construct(
        private ?string $projectId = null,
        private ?string $serviceAccountPath = null
    ) {
        $this->projectId = $this->projectId ?? config('services.fcm.project_id');
        $this->serviceAccountPath = $this->serviceAccountPath ?? config('services.fcm.service_account_path');
    }

    public function send(string $token, array $notification, array $data, array $context = []): void
    {
        $result = $this->sendToken($token, $notification, $data, $context);

        if ($result['status'] === 'retryable') {
            throw new RuntimeException('FCM v1 retryable error for token: ' . $token);
        }
    }

    public function sendMulticast(array $tokens, array $notification, array $data, array $context = []): array
    {
        $results = [
            'success' => [],
            'invalid' => [],
            'retryable' => [],
        ];

        if (empty($tokens)) {
            return $results;
        }

        $baseContext = array_merge([
            'type' => $data['type'] ?? null,
            'vehicle_uuid' => $data['vehicle_uuid'] ?? null,
            'transport' => 'fcm_http_v1',
            'transport_config_key' => 'services.fcm.transport',
            'transport_config_value' => config('services.fcm.transport'),
            'token_count' => count($tokens),
            'exception_class' => null,
            'exception_message' => null,
        ], $context);

        if (empty($this->projectId)) {
            Log::warning('push_config_error', array_merge($baseContext, [
                'reason' => 'project_id_missing',
                'exception_message' => 'FCM v1 project id is missing',
            ]));
            return $results;
        }

        $accessToken = $this->getAccessToken($baseContext);

        if (!$accessToken) {
            Log::warning('push_config_error', array_merge($baseContext, [
                'reason' => 'access_token_unavailable',
                'exception_message' => 'FCM v1 access token unavailable',
            ]));
            return $results;
        }

        $chunks = array_chunk($tokens, 500);

        foreach ($chunks as $index => $chunk) {
            $chunkContext = array_merge($baseContext, [
                'batch_index' => $index,
                'token_count' => count($chunk),
            ]);
            $chunkResults = $this->sendChunk($chunk, $notification, $data, $accessToken, $chunkContext);

            foreach (['success', 'invalid', 'retryable'] as $key) {
                $results[$key] = array_merge($results[$key], $chunkResults[$key]);
            }

            Log::info('push_sent', array_merge($chunkContext, [
                'success_count' => count($chunkResults['success']),
                'invalid_count' => count($chunkResults['invalid']),
                'retryable_count' => count($chunkResults['retryable']),
            ]));
        }

        return $results;
    }

    private function getAccessToken(array $context): ?string
    {
        $cacheKey = sprintf(
            'fcm_v1_access_token_%s',
            md5((string) $this->serviceAccountPath . '|' . (string) $this->projectId)
        );

        if ($cached = Cache::get($cacheKey)) {
            return $cached;
        }

        $serviceAccount = $this->loadServiceAccount($context);

        if (!$serviceAccount) {
            return null;
        }

        $assertion = $this->buildJwtAssertion($serviceAccount, $context);

        if (!$assertion) {
            return null;
        }

        $response = Http::asForm()
            ->timeout(10)
            ->post(self::OAUTH_TOKEN_ENDPOINT, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $assertion,
            ]);

        if ($response->serverError()) {
            Log::error('push_dispatch_failed', array_merge($context, [
                'reason' => 'fcm_v1_oauth_server_error',
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error.status'),
                'exception_class' => RuntimeException::class,
                'exception_message' => 'FCM v1 OAuth server error',
                'body' => $response->body(),
            ]));

            throw new RuntimeException('FCM v1 OAuth server error: ' . $response->status());
        }

        if ($response->clientError()) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'fcm_v1_oauth_client_error',
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error.status'),
                'exception_message' => $response->json('error.message'),
                'body' => $response->body(),
            ]));

            return null;
        }

        if ($response->failed()) {
            Log::error('push_dispatch_failed', array_merge($context, [
                'reason' => 'fcm_v1_oauth_unexpected_failure',
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error.status'),
                'body' => $response->body(),
            ]));

            $response->throw();
        }

        $accessToken = $response->json('access_token');

        if (!$accessToken) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'access_token_missing',
            ]));
            return null;
        }

        Cache::put($cacheKey, $accessToken, now()->addMinutes(50));

        return $accessToken;
    }

    private function sendChunk(array $tokens, array $notification, array $data, string $accessToken, array $context): array
    {
        $results = [
            'success' => [],
            'invalid' => [],
            'retryable' => [],
        ];

        foreach ($tokens as $token) {
            $result = $this->sendToken($token, $notification, $data, $context, $accessToken);
            $results[$result['status']][] = $token;
        }

        return $results;
    }

    private function sendToken(string $token, array $notification, array $data, array $context = [], ?string $accessToken = null): array
    {
        $context = array_merge([
            'token' => $token,
            'type' => $data['type'] ?? null,
            'vehicle_uuid' => $data['vehicle_uuid'] ?? null,
            'transport' => 'fcm_http_v1',
            'transport_config_key' => 'services.fcm.transport',
            'transport_config_value' => config('services.fcm.transport'),
        ], $context);

        if (empty($this->projectId)) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'project_id_missing',
                'exception_message' => 'FCM v1 project id is missing',
            ]));
            return ['status' => 'invalid'];
        }

        $endpoint = sprintf(self::FCM_ENDPOINT_TEMPLATE, $this->projectId);
        $tokenToUse = $accessToken ?? $this->getAccessToken($context);

        if (!$tokenToUse) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'access_token_unavailable',
                'exception_message' => 'FCM v1 access token unavailable',
            ]));
            return ['status' => 'invalid'];
        }

        $payload = [
            'message' => [
                'token' => $token,
                'notification' => $notification,
                'data' => $data,
            ],
        ];

        try {
            $response = Http::withToken($tokenToUse)
                ->timeout(10)
                ->post($endpoint, $payload);
        } catch (\Throwable $e) {
            Log::error('push_retryable_error', array_merge($context, [
                'exception_class' => get_class($e),
                'exception_message' => $e->getMessage(),
            ]));

            return ['status' => 'retryable'];
        }

        $status = $this->classifyResponse($response);

        if ($status === 'retryable') {
            Log::error('push_retryable_error', array_merge($context, [
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error.status'),
                'exception_message' => $response->json('error.message'),
                'body' => $response->body(),
            ]));
        } elseif ($status === 'invalid') {
            Log::warning('push_token_invalidated', array_merge($context, [
                'http_status' => $response->status(),
                'fcm_error_code' => $response->json('error.status'),
                'exception_message' => $response->json('error.message'),
                'body' => $response->body(),
            ]));
        } else {
            Log::info('push_sent', array_merge($context, [
                'http_status' => $response->status(),
            ]));
        }

        return ['status' => $status];
    }

    private function classifyResponse($response): string
    {
        if ($response->successful()) {
            return 'success';
        }

        if ($response->serverError()) {
            return 'retryable';
        }

        if ($response->clientError()) {
            $errorStatus = $response->json('error.status');
            $errorMessage = $response->json('error.message');
            $invalidCodes = ['UNREGISTERED', 'NOT_REGISTERED', 'INVALID_ARGUMENT'];

            if ($errorStatus && in_array($errorStatus, $invalidCodes, true)) {
                return 'invalid';
            }

            if ($errorMessage && $this->messageIndicatesInvalid($errorMessage, $invalidCodes)) {
                return 'invalid';
            }

            return 'invalid';
        }

        return $response->failed() ? 'retryable' : 'invalid';
    }

    private function messageIndicatesInvalid(string $message, array $invalidCodes): bool
    {
        foreach ($invalidCodes as $code) {
            if (str_contains($message, $code)) {
                return true;
            }
        }

        return false;
    }

    private function loadServiceAccount(array $context): ?array
    {
        if (empty($this->serviceAccountPath)) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'service_account_path_missing',
                'exception_message' => 'FCM v1 service account path missing',
            ]));
            return null;
        }

        $path = $this->resolvePath($this->serviceAccountPath);

        if (!$path || !is_readable($path)) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'service_account_unreadable',
                'exception_message' => 'FCM v1 service account file not readable',
                'path' => $this->serviceAccountPath,
            ]));
            return null;
        }

        $contents = file_get_contents($path);
        $data = json_decode($contents, true);

        if (!is_array($data)) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'service_account_invalid_json',
                'exception_message' => 'FCM v1 service account JSON is invalid',
                'path' => $path,
            ]));
            return null;
        }

        return $data;
    }

    private function buildJwtAssertion(array $serviceAccount, array $context): ?string
    {
        $clientEmail = $serviceAccount['client_email'] ?? null;
        $privateKey = $serviceAccount['private_key'] ?? null;

        if (!$clientEmail || !$privateKey) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'service_account_missing_fields',
                'exception_message' => 'FCM v1 service account missing client_email or private_key',
            ]));
            return null;
        }

        $now = time();
        $payload = [
            'iss' => $clientEmail,
            'scope' => self::OAUTH_SCOPE,
            'aud' => self::OAUTH_TOKEN_ENDPOINT,
            'exp' => $now + 3600,
            'iat' => $now,
        ];

        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT',
        ];

        $segments = [
            $this->base64UrlEncode(json_encode($header, JSON_THROW_ON_ERROR)),
            $this->base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR)),
        ];

        $signingInput = implode('.', $segments);
        $signature = '';

        $privateKeyResource = openssl_pkey_get_private($privateKey);

        if (!$privateKeyResource) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'invalid_private_key',
                'exception_message' => 'FCM v1 private key is invalid or unreadable',
            ]));
            return null;
        }

        if (!openssl_sign($signingInput, $signature, $privateKeyResource, 'SHA256')) {
            Log::warning('push_config_error', array_merge($context, [
                'reason' => 'jwt_signing_failed',
                'exception_message' => 'FCM v1 failed to sign JWT assertion',
            ]));
            openssl_free_key($privateKeyResource);
            return null;
        }

        openssl_free_key($privateKeyResource);

        $segments[] = $this->base64UrlEncode($signature);

        return implode('.', $segments);
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function resolvePath(string $path): ?string
    {
        if (is_file($path)) {
            return $path;
        }

        $candidate = base_path($path);

        if (is_file($candidate)) {
            return $candidate;
        }

        return null;
    }
}
