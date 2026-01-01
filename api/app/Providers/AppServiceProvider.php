<?php

namespace App\Providers;

use App\Services\Push\FcmV1Transport;
use App\Services\Push\LegacyFcmTransport;
use App\Services\Push\PushTransportInterface;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(PushTransportInterface::class, function ($app) {
            $configKey = 'services.fcm.transport';
            $transport = config($configKey, 'legacy');

            if (!in_array($transport, ['v1', 'legacy'], true)) {
                Log::warning('push_config_error', [
                    'reason' => 'transport_invalid',
                    'transport_config_key' => $configKey,
                    'transport_config_value' => $transport,
                    'transport_resolved' => 'legacy',
                ]);
                $transport = 'legacy';
            }

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

        Queue::failing(function (JobFailed $event) {
            $payload = $event->job->payload();
            $jobName = $event->job->resolveName();
            $jobClass = $payload['displayName'] ?? ($payload['data']['commandName'] ?? $jobName);
            $payloadExcerpt = $this->buildPayloadExcerpt($payload);
            $isPushRelated = $this->isPushRelatedJob($jobName, $payloadExcerpt);

            $context = [
                'job_name' => $jobName,
                'job_class' => $jobClass,
                'queue' => $event->job->getQueue(),
                'connection' => $event->connectionName,
                'attempts' => $event->job->attempts(),
                'payload' => $payloadExcerpt,
                'exception_class' => get_class($event->exception),
                'exception_message' => $event->exception->getMessage(),
                'is_push_related' => $isPushRelated,
            ];

            Log::error('queue_job_failed', $context);

            if ($isPushRelated) {
                Log::error('push_job_failed', $context);
            }
        });
    }

    private function buildPayloadExcerpt(array $payload): array
    {
        $excerpt = $payload;

        if (isset($excerpt['data']['command'])) {
            $excerpt['data']['command'] = Str::limit((string) $excerpt['data']['command'], 300);
        }

        return $excerpt;
    }

    private function isPushRelatedJob(string $jobName, array $payloadExcerpt): bool
    {
        $haystack = strtolower($jobName . ' ' . json_encode($payloadExcerpt));

        return str_contains($haystack, 'push') || str_contains($haystack, 'fcm');
    }
}
