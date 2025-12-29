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
            return response()->json(['error' => 'This tag belongs to another user'], 403);
        }

        // Ekle veya güncelle
        $vehicle = Vehicle::updateOrCreate(
            ['vehicle_id' => $req->vehicle_id],
            ['user_id' => auth()->id()]
        );

        return response()->json(['vehicle' => $vehicle]);
    }

    public function myVehicles()
    {
        return response()->json(auth()->user()->vehicles);
    }

    public function info($vehicleId)
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)->first();

        if (!$vehicle) {
            return response()->json(['error' => 'Vehicle not found'], 404);
        }

        if ($vehicle->user_id !== auth()->id()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json($vehicle);
    }
}
