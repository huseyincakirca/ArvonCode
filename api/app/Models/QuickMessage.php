<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuickMessage extends Model
{
    protected $table = 'quick_messages';

    protected $fillable = [
        'text',
        'is_active',
    ];
}
