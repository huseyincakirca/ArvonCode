<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\QuickMessage;

class QuickMessageSeeder extends Seeder
{
    public function run(): void
    {
        $messages = [
            '5 dk geliyorum',
            'Acil, aşağıdan ulaşın',
            'Aracınız yolu kapatıyor',
            'Otopark görevlisiyim',
            'Aracı bulamadım',
        ];

        foreach ($messages as $text) {
            QuickMessage::create([
                'text' => $text,
                'is_active' => true,
            ]);
        }
    }
}
