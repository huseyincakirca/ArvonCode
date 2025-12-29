<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PublicRequestLog extends Model
{
    use HasFactory;
    protected $fillable = [
        'endpoint',
        'method',
        'ip',
        'user_agent',
        'vehicle_uuid',
        'vehicle_id',
        'ok',
        'status_code',
        'error_code',
        'error_message'
    ];
}
