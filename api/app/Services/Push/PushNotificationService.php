<?php

namespace App\Services\Push;

class PushNotificationService
{
    public function __construct(private LegacyFcmTransport $legacyFcmTransport)
    {
    }

    public function sendToTokens(array $tokens, string $type, string $vehicleUuid, string $createdAt): void
    {
        $payload = $this->buildPayload($type, $vehicleUuid, $createdAt);

        foreach ($tokens as $token) {
            $this->legacyFcmTransport->send(
                $token,
                $payload['notification'],
                $payload['data']
            );
        }
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
}
