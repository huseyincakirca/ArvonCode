<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Requests\PublicQuickMessageSendRequest;
use App\Models\Message;
use App\Models\QuickMessage;
use App\Models\Vehicle;
use App\Events\OwnerNotifiableEvent;

class QuickMessageController extends Controller
{
    public function index()
    {
        $items = QuickMessage::query()
            ->where('is_active', 1)
            ->orderBy('id')
            ->get(['id', 'text']);

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
        $vehicle = Vehicle::query()
            ->select('id', 'vehicle_id', 'user_id')
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
        $qm = QuickMessage::query()
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
        $message = Message::create([
            'vehicle_id' => $vehicle->id,            // DİKKAT: numeric vehicles.id
            'message' => $qm->text,                  // hızlı mesaj metni
            'phone' => $validated['phone'] ?? null,
            'sender_ip' => $request->ip(),
        ]);

        if ($vehicle->user_id) {
            event(new OwnerNotifiableEvent(
                $vehicle->user_id,
                'message',
                $vehicle->vehicle_id,
                $message->created_at->toISOString()
            ));
        }

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
