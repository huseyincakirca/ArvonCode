<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
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
