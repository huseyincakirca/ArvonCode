<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Parking extends Model
{
    protected $fillable = ['vehicle_id','lat','lng','parked_at'];

    public function vehicle() {
        return $this->belongsTo(Vehicle::class);
    }
}

