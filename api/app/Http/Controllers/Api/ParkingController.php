<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Parking;
use App\Models\Vehicle;

class ParkingController extends Controller
{
    public function setParking(Request $req)
    {
        $req->validate([
            'vehicle_id' => 'required',
            'lat' => 'required',
            'lng' => 'required',
        ]);

        $vehicle = Vehicle::where('vehicle_id', $req->vehicle_id)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json(['error' => 'Unauthorized vehicle'], 403);
        }

        $parking = Parking::create([
            'vehicle_id' => $vehicle->id,
            'lat' => $req->lat,
            'lng' => $req->lng,
            'parked_at' => now()
        ]);

        return response()->json(['parking' => $parking]);
    }

    public function latest($vehicleId)
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $parking = $vehicle->parking()->latest('id')->first();

        return response()->json(['parking' => $parking]);
    }

    public function deleteParking($vehicleId)
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        Parking::where('vehicle_id', $vehicle->id)->delete();

        return response()->json(['status' => 'deleted']);
    }
}
