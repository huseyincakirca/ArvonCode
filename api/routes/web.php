<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// PUBLIC VIEW ROUTE SİLİNDİ
// Sadece API kullanılacak
