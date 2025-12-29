<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Requests\PublicQuickMessageSendRequest;

class QuickMessageController extends Controller
{
    public function index()
    {
        $items = DB::table('quick_messages')
            ->select('id', 'text')
            ->where('is_active', 1)
            ->orderBy('id')
            ->get();

        return response()->json([
            'ok' => true,
            'message' => 'Quick messages',
            'data' => $items,
        ]);
    }
    public function send(PublicQuickMessageSendRequest $request)
    {
        $validated = $request->validated();

        // 1) vehicle_uuid -> vehicles tablosunda ara (vehicles.vehicle_id alanı!)
        $vehicle = DB::table('vehicles')
            ->select('id', 'vehicle_id')
            ->where('vehicle_id', $validated['vehicle_uuid'])
            ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Vehicle not found',
                'error_code' => 'VEHICLE_NOT_FOUND',
                'errors' => ['vehicle_uuid' => ['Invalid vehicle_uuid']],
            ], 404);
        }

        // 2) quick_message_id -> quick_messages tablosunda ara (aktif olmalı)
        $qm = DB::table('quick_messages')
            ->select('id', 'text')
            ->where('id', $validated['quick_message_id'])
            ->where('is_active', 1)
            ->first();

        if (!$qm) {
            return response()->json([
                'ok' => false,
                'message' => 'Quick message not found',
                'error_code' => 'VEHICLE_NOT_FOUND',
                'errors' => ['quick_message_id' => ['Invalid quick_message_id']],
            ], 404);
        }

        // 3) messages tablosuna kaydet
        DB::table('messages')->insert([
            'vehicle_id' => $vehicle->id,            // DİKKAT: numeric vehicles.id
            'message' => $qm->text,                  // hızlı mesaj metni
            'phone' => $validated['phone'] ?? null,
            'sender_ip' => $request->ip(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'ok' => true,
            'message' => 'Message sent',
            'data' => [
                'vehicle_uuid' => $validated['vehicle_uuid'],
                'quick_message_id' => $qm->id,
            ],
        ]);
    }
}
