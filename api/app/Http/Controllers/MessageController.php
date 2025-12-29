<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Message;
use App\Models\Vehicle;

class MessageController extends Controller
{
    // Owner (Araç Sahibi) gelen kutusu
    public function index(Request $request)
    {
        // 1. Giriş yapan kullanıcıyı al
        $user = $request->user();

        // 2. Bu kullanıcının araçlarının ID'lerini al (Örn: [1, 5, 8])
        $vehicleIds = Vehicle::where('user_id', $user->id)->pluck('id');

        // 3. Bu araç ID'lerine ait mesajları bul
        // 'vehicle' ile beraber çekiyoruz ki mesajın hangi arabaya geldiğini bilelim
        $messages = Message::whereIn('vehicle_id', $vehicleIds)
            ->with('vehicle') // İlişkiyi yükle (plaka vs için)
            ->orderByDesc('created_at') // En yeni en üstte
            ->orderByDesc('id') // Aynı timestamp'te deterministik sırala
            ->get();

        // 4. Standart formatta döndür
        return response()->json([
            'ok' => true,
            'message' => 'Messages retrieved',
            'data' => $messages
        ]);
    }

    // Owner (Araç Sahibi) son mesaj
    public function latest(Request $request)
    {
        $user = $request->user();

        $vehicleIds = Vehicle::where('user_id', $user->id)->pluck('id');

        $message = Message::whereIn('vehicle_id', $vehicleIds)
            ->with('vehicle')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->first();

        return response()->json([
            'ok' => true,
            'message' => $message ? 'Latest message retrieved' : 'Latest message not found',
            'data' => $message
        ]);
    }
}
