<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Validation\ValidationException;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    public function render($request, Throwable $e)
    {
        if ($e instanceof ThrottleRequestsException) {
            $path = ltrim($request->path(), '/');
            $isLogin = str_starts_with($path, 'api/login') || str_starts_with($path, 'api/register') || str_starts_with($path, 'api/logout');
            $isPublic = str_starts_with($path, 'api/public');

            if ($isLogin) {
                $message = 'Too many login attempts';
                $errorCode = 'AUTH_RATE_LIMIT';
            } elseif ($isPublic) {
                $message = 'Too many requests';
                $errorCode = 'PUBLIC_RATE_LIMIT';
            } else {
                $message = 'Too many requests';
                $errorCode = 'RATE_LIMIT';
            }

            return response()->json([
                'ok' => false,
                'message' => $message,
                'error_code' => $errorCode,
                'data' => new \stdClass(),
            ], 429);
        }

        return parent::render($request, $e);
    }

    protected function invalidJson($request, ValidationException $exception)
    {
        return response()->json([
            'ok' => false,
            'message' => $exception->getMessage(),
            'errors' => $exception->errors(),
            'data' => new \stdClass(),
        ], $exception->status);
    }

    protected function unauthenticated($request, AuthenticationException $exception)
    {
        return response()->json([
            'ok' => false,
            'message' => 'Unauthenticated',
            'error_code' => 'UNAUTHENTICATED',
            'data' => new \stdClass(),
        ], 401);
    }
}
