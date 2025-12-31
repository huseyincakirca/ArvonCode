<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * The path to your application's "home" route.
     *
     * Typically, users are redirected here after authentication.
     *
     * @var string
     */
    public const HOME = '/home';

    /**
     * Define your route model bindings, pattern filters, and other route configuration.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('public.base', function (Request $request) {
            // Baz koruma: IP başına dakikada 60 public istek (genel trafik kontrolü)
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('public.quick-messages', function (Request $request) {
            // Listeleme endpoint’i: IP başına dakikada 30 (ağır listelemeyi sınırlar)
            return Limit::perMinute(30)->by($request->ip());
        });

        RateLimiter::for('public.vehicle', function (Request $request) {
            $vehicleUuid = (string) $request->route('vehicle_uuid');
            $key = $request->ip().'|vehicle:'.$vehicleUuid;
            // Profil sorgusu: aynı IP + vehicle kombinasyonu dakikada 20 (scraping’i sınırlar)
            return Limit::perMinute(20)->by($key);
        });

        RateLimiter::for('public.quick-message.send', function (Request $request) {
            $vehicleUuid = (string) $request->input('vehicle_uuid', $request->route('vehicle_uuid'));
            $key = $request->ip().'|quick-message:'.$vehicleUuid;
            // Aynı araç + IP için dakikada 5 mesaj (spam blokaj)
            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('public.message', function (Request $request) {
            $vehicleUuid = (string) $request->input('vehicle_uuid', $request->route('vehicle_uuid'));
            $key = $request->ip().'|message:'.$vehicleUuid;
            // Özel mesaj için aynı araç + IP dakikada 5 (spam/abuse engeli)
            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('public.location', function (Request $request) {
            $vehicleUuid = (string) $request->input('vehicle_uuid', $request->route('vehicle_uuid'));
            $key = $request->ip().'|location:'.$vehicleUuid;
            // Konum kaydı: aynı araç + IP dakikada 5 (GPS spam’ini sınırlar)
            return Limit::perMinute(5)->by($key);
        });

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }
}
