<?php

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OwnerNotifiableEvent
{
    use Dispatchable, SerializesModels;

    public int $ownerId;
    public string $type;
    public int $vehicleId;
    public string $createdAt;

    public function __construct(int $ownerId, string $type, int $vehicleId, string $createdAt)
    {
        $this->ownerId = $ownerId;
        $this->type = $type;
        $this->vehicleId = $vehicleId;
        $this->createdAt = $createdAt;
    }
}
