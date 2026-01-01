<?php

namespace App\Providers;

use App\Services\Push\FcmV1Transport;
use App\Services\Push\LegacyFcmTransport;
use App\Services\Push\PushTransportInterface;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(PushTransportInterface::class, function ($app) {
            $transport = config('services.fcm.transport', 'legacy');

            return match ($transport) {
                'v1' => $app->make(FcmV1Transport::class),
                default => $app->make(LegacyFcmTransport::class),
            };
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (app()->environment('staging')) {
            $defaultConnection = config('database.default');
            $database = config("database.connections.{$defaultConnection}.database");
            $productionDatabase = 'car_nfc';

            if ($database === $productionDatabase) {
                throw new \RuntimeException('Staging environment cannot use the production database.');
            }
        }
    }
}
