<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\VehicleController;
use App\Http\Controllers\Api\ParkingController;
use App\Http\Controllers\Api\PublicController;
// MessageController eksik olabilir, onu da ekledim garanti olsun
use App\Http\Controllers\MessageController;
use App\Http\Controllers\QuickMessageController;
use App\Http\Controllers\LocationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Auth İşlemleri
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Korumalı Alan (Sadece giriş yapmış kullanıcılar)
Route::middleware('auth:sanctum')->group(function () {

    // Araç işlemleri
    Route::post('/vehicle/activate', [VehicleController::class, 'activate']);
    Route::get('/vehicle/my', [VehicleController::class, 'myVehicles']);
    Route::get('/vehicle/{id}', [VehicleController::class, 'info']);
    Route::get('/vehicles', [VehicleController::class, 'myVehicles']);

    // Mesaj İşlemleri (BURASI EKLENDİ)
    Route::get('/messages/latest', [MessageController::class, 'latest']);
    Route::get('/messages', [MessageController::class, 'index']);

    // Konum İşlemleri
    Route::get('/locations', [LocationController::class, 'index']);

    // Park işlemleri (Eski kodların)
    Route::post('/parking/set', [ParkingController::class, 'setParking']);
    Route::get('/parking/latest/{id}', [ParkingController::class, 'latest']);
    Route::delete('/parking/delete/{id}', [ParkingController::class, 'deleteParking']);

    // Push Notification ID Kaydetme
    Route::post('/user/push-id', [AuthController::class, 'savePushId']);
});

// Eski public route'lar (geriye dönük uyumluluk için durabilir veya silebilirsin, aşağıda yenileri var)
Route::get('/v/{tag}', [PublicController::class, 'viewVehicle']);
Route::post('/v/{tag}/message', [PublicController::class, 'sendMessage']);

// Public (Ziyaretçi) İşlemleri
Route::prefix('public')
    ->middleware(['throttle:public', 'public.log'])
    ->group(function () {
        Route::get('/quick-messages', [QuickMessageController::class, 'index']);
        Route::post('/quick-message/send', [QuickMessageController::class, 'send']);
        Route::get('/vehicle/{vehicle_uuid}', [PublicController::class, 'vehicleProfile']);
        Route::post('/location/save', [LocationController::class, 'save']);
        Route::post('/message', [PublicController::class, 'sendMessage']);
    });
