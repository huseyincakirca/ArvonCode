<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Vehicle;   // <-- EKSİKTİ
use App\Models\Location;
use App\Http\Requests\PublicLocationSaveRequest;


class LocationController extends Controller
{
    public function save(PublicLocationSaveRequest $request)
    {
        // 1️⃣ SADECE BURADAN OKUYACAKSIN
        $validated = $request->validated();

        // 2️⃣ vehicle_uuid → validated içinden
        $vehicle = Vehicle::where('vehicle_id', $validated['vehicle_uuid'])->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Vehicle not found',
                'error_code' => 'VEHICLE_NOT_FOUND',
            ], 404);
        }

        // 3️⃣ Location kaydı
        $location = Location::create([
            'vehicle_id' => $vehicle->id,
            'lat'        => $validated['lat'],
            'lng'        => $validated['lng'],
            'accuracy'   => $validated['accuracy'] ?? null,
            'source'     => 'guest_qr',
        ]);

        return response()->json([
            'ok' => true,
            'message' => 'Location saved',
            'data' => $location,
        ], 200);
    }

    // ---- AUTH'lu taraf (dokunma, doğru)
    public function index(Request $request)
    {
        $user = $request->user();

        $locations = Location::query()
            ->whereHas('vehicle', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            })
            ->with(['vehicle:id,vehicle_id,plate,brand,model,color'])
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'ok' => true,
            'message' => 'Locations',
            'data' => $locations,
        ], 200);
    }
}
