<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\VehicleController;
use App\Http\Controllers\Api\ParkingController;
use App\Http\Controllers\Api\PublicController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\QuickMessageController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\UserPushTokenController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Auth İşlemleri
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');

// Korumalı Alan (Sadece giriş yapmış kullanıcılar)
Route::middleware('auth:sanctum')->group(function () {

    // Araç işlemleri
    Route::post('/vehicle/activate', [VehicleController::class, 'activate']);
    Route::get('/vehicle/my', [VehicleController::class, 'myVehicles']);
    Route::get('/vehicle/{id}', [VehicleController::class, 'info']);
    Route::get('/vehicles', [VehicleController::class, 'myVehicles']);

    // Mesaj İşlemleri
    Route::get('/messages/latest', [MessageController::class, 'latest']);
    Route::get('/messages', [MessageController::class, 'index']);

    // Konum İşlemleri
    Route::get('/locations', [LocationController::class, 'index']);

    // Park işlemleri (Eski kodların)
    Route::post('/parking/set', [ParkingController::class, 'setParking']);
    Route::get('/parking/latest/{id}', [ParkingController::class, 'latest']);
    Route::delete('/parking/delete/{id}', [ParkingController::class, 'deleteParking']);

    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);

    // Push Notification ID Kaydetme
    Route::post('/user/push-id', [UserPushTokenController::class, 'store']);
});

// Public (Ziyaretçi) İşlemleri
Route::prefix('public')
    ->middleware(['public.log', 'throttle:public.base'])
    ->group(function () {
        Route::get('/quick-messages', [QuickMessageController::class, 'index'])
            ->middleware('throttle:public.quick-messages');

        Route::post('/quick-message/send', [QuickMessageController::class, 'send'])
            ->middleware('throttle:public.quick-message.send');

        Route::get('/vehicle/{vehicle_uuid}', [PublicController::class, 'vehicleProfile'])
            ->middleware('throttle:public.vehicle');

        Route::post('/location/save', [LocationController::class, 'save'])
            ->middleware('throttle:public.location');

        Route::post('/message', [PublicController::class, 'sendMessage'])
            ->middleware('throttle:public.message');
    });
