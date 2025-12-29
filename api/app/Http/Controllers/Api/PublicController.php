<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Vehicle;
use App\Models\User;
use App\Models\QuickMessage;

class PublicController extends Controller
{
    // Kart okutulunca araç bilgisi döndür
    public function viewVehicle($tag)
    {
        $tag = trim($tag);
        // Global scope'ları kapat -> user_id filtresi devre dışı
        $vehicle = Vehicle::withoutGlobalScopes()
            ->where('vehicle_id', $tag)
            ->first();

        if (!$vehicle) {
            return response()->json(['error' => 'Araç bulunamadı'], 404);
        }

        return response()->json([
            'vehicle' => $vehicle,
            'owner'   => $vehicle->user,
        ]);
    }

    // Kart üzerinden araç sahibine mesaj gönder
    public function sendMessage(Request $request)
    {
        // 1️⃣ VALIDATION (public standart)
        $validated = $request->validate([
            'vehicle_uuid' => 'required|string',
            'message' => 'required|string|max:500',
            'phone' => 'nullable|string|max:50',
        ]);

        // 2️⃣ vehicle_uuid → vehicles.id (numeric)
        $vehicle = Vehicle::withoutGlobalScopes()
            ->where('vehicle_id', trim($validated['vehicle_uuid']))
            ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Vehicle not found',
                'error_code' => 'VEHICLE_NOT_FOUND',
            ], 404);
        }

        // 3️⃣ Mesajı messages tablosuna yaz
        $message = \App\Models\Message::create([
            'vehicle_id' => $vehicle->id, // numeric ID
            'message' => $validated['message'],
            'phone' => $validated['phone'] ?? null,
            'sender_ip' => $request->ip(),
        ]);

        // 4️⃣ Standart response
        return response()->json([
            'ok' => true,
            'message' => 'Message sent',
            'data' => [
                'message_id' => $message->id,
                'vehicle_uuid' => $vehicle->vehicle_id,
            ]
        ], 200);
    }



    public function vehicleProfile($vehicle_uuid)
    {
        $vehicle = Vehicle::withoutGlobalScopes()
            ->where('vehicle_id', trim($vehicle_uuid))
            ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Vehicle not found',
                'data' => null
            ], 404);
        }

        $quickMessages = QuickMessage::where('is_active', true)
            ->orderBy('id')
            ->get(['id', 'text']);

        return response()->json([
            'ok' => true,
            'message' => 'Vehicle found',
            'data' => [
                'vehicle_uuid' => $vehicle->vehicle_id,
                'plate' => $vehicle->plate,
                'brand' => $vehicle->brand,
                'model' => $vehicle->model,
                'color' => $vehicle->color,
                'quick_messages' => $quickMessages
            ]
        ]);
    }
}
