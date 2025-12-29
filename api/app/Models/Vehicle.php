<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    protected $fillable = ['user_id','vehicle_id','plate','brand','model','color'];

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function parking()
    {
        return $this->hasOne(Parking::class)->latestOfMany();
    }

}

