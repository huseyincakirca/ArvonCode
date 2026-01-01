<?php

namespace App\Services\Push;

class PushNotificationService
{
    public function __construct(private PushTransportInterface $transport)
    {
    }

    public function sendToTokens(array $tokens, string $type, string $vehicleUuid, string $createdAt): array
    {
        $payload = $this->buildPayload($type, $vehicleUuid, $createdAt);

        return $this->transport->sendMulticast(
            $tokens,
            $payload['notification'],
            $payload['data']
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
}
