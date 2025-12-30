<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Vehicle;

class VehicleController extends Controller
{
    public function activate(Request $req)
    {
        $req->validate([
            'vehicle_id' => 'required'
        ]);

        // Etiket başka kullanıcıya ait mi?
        $exists = Vehicle::where('vehicle_id', $req->vehicle_id)->first();

        if ($exists && $exists->user_id != auth()->id()) {
            return response()->json([
                'ok' => false,
                'message' => 'This tag belongs to another user',
                'data' => new \stdClass(),
            ], 403);
        }

        // Ekle veya güncelle
        $vehicle = Vehicle::updateOrCreate(
            ['vehicle_id' => $req->vehicle_id],
            ['user_id' => auth()->id()]
        );

        return response()->json([
            'ok' => true,
            'message' => 'Vehicle activated',
            'data' => [
                'vehicle' => $vehicle,
            ],
        ]);
    }

    public function myVehicles()
    {
        /** @var \App\Models\User $user */
        $user = auth()->user();
        return response()->json([
            'ok' => true,
            'message' => 'My vehicles',
            'data' => $user->vehicles,
        ]);
    }

    public function info($vehicleId)
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Vehicle not found',
                'data' => new \stdClass(),
            ], 404);
        }

        if ($vehicle->user_id !== auth()->id()) {
            return response()->json([
                'ok' => false,
                'message' => 'Unauthorized',
                'data' => new \stdClass(),
            ], 403);
        }

        return response()->json([
            'ok' => true,
            'message' => 'Vehicle info',
            'data' => $vehicle,
        ]);
    }
}
