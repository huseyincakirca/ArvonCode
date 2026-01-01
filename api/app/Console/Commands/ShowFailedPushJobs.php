<?php

namespace App\Console\Commands;

use App\Jobs\SendPushNotificationJob;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ShowFailedPushJobs extends Command
{
    protected $signature = 'show:failed-push-jobs {--limit=20 : Number of failed jobs to display}';

    protected $description = 'Inspect recent failed push-related jobs with payload excerpts';

    public function handle(): int
    {
        $limit = (int) $this->option('limit');
        try {
            $failed = DB::table('failed_jobs')
                ->orderByDesc('failed_at')
                ->limit($limit)
                ->get();
        } catch (\Throwable $e) {
            $this->error('Failed to read failed_jobs: ' . $e->getMessage());
            return self::FAILURE;
        }

        if ($failed->isEmpty()) {
            $this->info('No failed jobs found.');
            return self::SUCCESS;
        }

        $shown = 0;

        foreach ($failed as $job) {
            $payload = $this->decodePayload($job->payload);
            $details = $this->extractDetailsFromCommand($payload);
            $jobClass = $details['job_class'] ?? $this->resolveJobClass($payload);
            $isPushRelated = $this->isPushRelated($jobClass, $payload);

            if (!$isPushRelated) {
                continue;
            }

            $shown++;

            $this->line(str_repeat('-', 80));
            $this->line(sprintf(
                'ID #%s | Failed At: %s | Connection: %s | Queue: %s',
                $job->id,
                $job->failed_at,
                $job->connection,
                $job->queue
            ));
            $this->line('Job: ' . ($jobClass ?? 'unknown'));
            $this->line(sprintf(
                'Attempts: %s | MaxTries: %s',
                $details['attempts'] ?? $payload['attempts'] ?? 'n/a',
                $details['max_tries'] ?? $payload['maxTries'] ?? 'n/a'
            ));

            if (isset($details['owner_id']) || isset($details['vehicle_uuid']) || isset($details['vehicle_id'])) {
                $this->line(sprintf(
                    'Owner ID: %s | Vehicle UUID: %s | Vehicle ID: %s',
                    $details['owner_id'] ?? 'n/a',
                    $details['vehicle_uuid'] ?? 'n/a',
                    $details['vehicle_id'] ?? 'n/a'
                ));
            }

            if (isset($details['token_count'])) {
                $this->line('Token count: ' . $details['token_count']);
            }

            $this->line('Exception: ' . $this->shortenException($job->exception));
            $this->line('Payload excerpt: ' . $this->buildPayloadExcerpt($payload));
        }

        if ($shown === 0) {
            $this->info('No push-related failed jobs found.');
        }

        return self::SUCCESS;
    }

    private function decodePayload(string $payload): array
    {
        $decoded = json_decode($payload, true);

        return is_array($decoded) ? $decoded : [];
    }

    private function resolveJobClass(array $payload): ?string
    {
        return $payload['displayName'] ?? $payload['data']['commandName'] ?? null;
    }

    private function buildPayloadExcerpt(array $payload): string
    {
        try {
            return Str::limit(json_encode($payload, JSON_THROW_ON_ERROR), 500);
        } catch (\Throwable $e) {
            return 'payload_unencodable: ' . Str::limit($e->getMessage(), 150);
        }
    }

    private function shortenException(string $exception): string
    {
        $firstLine = strtok($exception, "\n") ?: $exception;

        return Str::limit($firstLine, 300);
    }

    private function isPushRelated(?string $jobClass, array $payload): bool
    {
        $haystack = strtolower(($jobClass ?? '') . ' ' . json_encode($payload));

        return str_contains($haystack, 'push') || str_contains($haystack, 'fcm');
    }

    private function extractDetailsFromCommand(array $payload): array
    {
        $command = $payload['data']['command'] ?? null;

        if (!$command) {
            return [];
        }

        try {
            $job = unserialize($command, ['allowed_classes' => true]);
        } catch (\Throwable $e) {
            return [
                'command_unserialize_error' => $e->getMessage(),
            ];
        }

        if ($job instanceof SendPushNotificationJob) {
            $vehicleUuid = $job->vehicleUuid ?? null;
            $vehicleId = $vehicleUuid
                ? DB::table('vehicles')->where('vehicle_id', $vehicleUuid)->value('id')
                : null;

            return [
                'job_class' => SendPushNotificationJob::class,
                'vehicle_uuid' => $vehicleUuid,
                'vehicle_id' => $vehicleId,
                'owner_id' => $job->ownerId ?? null,
                'token_count' => is_array($job->tokens ?? null) ? count($job->tokens) : null,
                'attempts' => method_exists($job, 'attempts') ? $job->attempts() : null,
                'max_tries' => $job->tries ?? null,
            ];
        }

        return [
            'job_class' => is_object($job) ? get_class($job) : ($payload['displayName'] ?? null),
        ];
    }
}
