<?php

namespace App\Console\Commands;

use App\Models\PublicRequestLog;
use Illuminate\Console\Command;

class ShowPublicRequestLogs extends Command
{
    protected $signature = 'public:logs {--limit=50 : Number of latest logs to show}';

    protected $description = 'List recent public_request_logs (read-only, non-production)';

    public function handle(): int
    {
        if (! in_array(config('app.env'), ['local', 'staging', 'testing'])) {
            $this->error('public:logs is disabled in production.');
            return self::FAILURE;
        }

        $logs = PublicRequestLog::orderByDesc('id')
            ->limit((int) $this->option('limit'))
            ->get(['id', 'endpoint', 'method', 'ip', 'vehicle_uuid', 'status_code', 'error_code', 'created_at']);

        $this->table(
            ['ID', 'Endpoint', 'Method', 'IP', 'Vehicle UUID', 'Status', 'Error Code', 'Created At'],
            $logs->map(fn ($log) => [
                $log->id,
                $log->endpoint,
                $log->method,
                $log->ip,
                $log->vehicle_uuid,
                $log->status_code,
                $log->error_code,
                $log->created_at,
            ])->toArray()
        );

        return self::SUCCESS;
    }
}
