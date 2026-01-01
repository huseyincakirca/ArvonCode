<?php

namespace App\Services\Push;

use App\Services\Push\FcmV1Transport;

class PushNotificationService
{
    public function __construct(private PushTransportInterface $transport)
    {
    }

    public function sendToTokens(array $tokens, string $type, string $vehicleUuid, string $createdAt, array $context = []): array
    {
        $payload = $this->buildPayload($type, $vehicleUuid, $createdAt);
        $transportContext = $this->buildTransportContext();
        $baseContext = array_merge($transportContext, [
            'type' => $type,
            'vehicle_uuid' => $vehicleUuid,
            'token_count' => count($tokens),
        ], $context);

        return $this->transport->sendMulticast(
            $tokens,
            $payload['notification'],
            $payload['data'],
            $baseContext
        );
    }

    public function buildPayload(string $type, string $vehicleUuid, string $createdAt): array
    {
        return [
            'notification' => [
                'title' => $this->buildTitle($type),
                'body' => 'Tap to view details',
            ],
            'data' => [
                'type' => $type,
                'vehicle_uuid' => $vehicleUuid,
                'created_at' => $createdAt,
            ],
        ];
    }

    private function buildTitle(string $type): string
    {
        return $type === 'location' ? 'New location received' : 'New message received';
    }

    public function getTransportContext(): array
    {
        return $this->buildTransportContext();
    }

    private function buildTransportContext(): array
    {
        $configKey = 'services.fcm.transport';
        $configuredTransport = config($configKey, 'legacy');
        $resolvedTransport = $this->transport instanceof FcmV1Transport ? 'fcm_http_v1' : 'legacy';

        return [
            'transport' => $resolvedTransport,
            'transport_config_key' => $configKey,
            'transport_config_value' => $configuredTransport,
        ];
    }
}
