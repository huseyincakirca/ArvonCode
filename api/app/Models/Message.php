<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = [
        'vehicle_id',
        'message',
        'phone',
        'sender_ip',
    ];

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }
}

