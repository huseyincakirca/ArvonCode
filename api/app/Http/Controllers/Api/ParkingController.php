<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Parking;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;

class ParkingController extends Controller
{
    public function setParking(Request $req): JsonResponse
    {
        $req->validate([
            'vehicle_id' => 'required|string',
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        $vehicle = Vehicle::where('vehicle_id', $req->vehicle_id)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Unauthorized vehicle',
                'data' => new \stdClass(),
            ], 403);
        }

        $parking = Parking::create([
            'vehicle_id' => $vehicle->id,
            'lat' => $req->lat,
            'lng' => $req->lng,
            'parked_at' => now()
        ]);

        return response()->json([
            'ok' => true,
            'message' => 'Parking saved',
            'data' => [
                'parking' => $parking,
            ],
        ]);
    }

    public function latest($vehicleId): JsonResponse
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Unauthorized vehicle',
                'data' => new \stdClass(),
            ], 403);
        }

        $parking = $vehicle->parking()->latest('id')->first();

        return response()->json([
            'ok' => true,
            'message' => 'Latest parking fetched',
            'data' => [
                'parking' => $parking,
            ],
        ]);
    }

    public function deleteParking($vehicleId): JsonResponse
    {
        $vehicle = Vehicle::where('vehicle_id', $vehicleId)
                          ->where('user_id', auth()->id())
                          ->first();

        if (!$vehicle) {
            return response()->json([
                'ok' => false,
                'message' => 'Unauthorized vehicle',
                'data' => new \stdClass(),
            ], 403);
        }

        Parking::where('vehicle_id', $vehicle->id)->delete();

        return response()->json([
            'ok' => true,
            'message' => 'Parking deleted',
            'data' => new \stdClass(),
        ]);
    }
}
