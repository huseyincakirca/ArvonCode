<?php

namespace App\Services\Push;

interface PushTransportInterface
{
    public function send(string $token, array $notification, array $data): void;
}
