<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PublicRequestLogger
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle($request, Closure $next)
    {
        $vehicleUuid =
            $request->route('vehicle_uuid')
            ?? $request->input('vehicle_uuid');

        $response = $next($request);

        try {
            $payload = null;
            // JSON response ise ok alanını yakala
            if (method_exists($response, 'getContent')) {
                $content = $response->getContent();
                $payload = json_decode($content, true);
            }

            \App\Models\PublicRequestLog::create([
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'ip' => $request->ip(),
                'user_agent' => substr((string)$request->userAgent(), 0, 255),
                'vehicle_uuid' => $vehicleUuid,
                'ok' => (bool)($payload['ok'] ?? false),
                'status_code' => $response->getStatusCode(),
                'error_message' => isset($payload['ok']) && !$payload['ok'] ? ($payload['message'] ?? null) : null,
            ]);
        } catch (\Throwable $e) {
            // log başarısızsa request’i bozma
        }

        return $response;
    }
}
