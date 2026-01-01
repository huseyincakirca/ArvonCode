<?php

namespace App\Http\Middleware;

use App\Exceptions\Handler;
use App\Models\PublicRequestLog;
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

        try {
            $response = $next($request);
        } catch (\Throwable $e) {
            // Exception durumlarını da loglayabilmek için Handler üzerinden response üret.
            app(Handler::class)->report($e);
            $response = app(Handler::class)->render($request, $e);
        }

        $payload = [];
        if (method_exists($response, 'getContent')) {
            $payload = json_decode($response->getContent(), true) ?: [];
        }

        $ok = (bool)($payload['ok'] ?? ($response->getStatusCode() < 400));
        $errorCode = $payload['error_code'] ?? null;

        try {
            PublicRequestLog::create([
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'ip' => $request->ip(),
                'user_agent' => substr((string) $request->userAgent(), 0, 255),
                'vehicle_uuid' => $vehicleUuid,
                'ok' => $ok,
                'status_code' => $response->getStatusCode(),
                'error_code' => $errorCode,
                'error_message' => $ok ? null : ($payload['message'] ?? null),
            ]);
        } catch (\Throwable $e) {
            // log başarısızsa request’i bozma
        }

        return $response;
    }
}
