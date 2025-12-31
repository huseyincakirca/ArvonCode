<?php

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OwnerNotifiableEvent
{
    use Dispatchable, SerializesModels;

    public int $ownerId;
    public string $type;
    public string $vehicleUuid;
    public string $createdAt;

    public function __construct(int $ownerId, string $type, string $vehicleUuid, string $createdAt)
    {
        $this->ownerId = $ownerId;
        $this->type = $type;
        $this->vehicleUuid = $vehicleUuid;
        $this->createdAt = $createdAt;
    }
}
