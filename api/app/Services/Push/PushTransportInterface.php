<?php

namespace App\Services\Push;

interface PushTransportInterface
{
    public function send(string $token, array $notification, array $data): void;

    /**
     * @return array{success: array<int,string>, invalid: array<int,string>, retryable: array<int,string>}
     */
    public function sendMulticast(array $tokens, array $notification, array $data): array;
}
