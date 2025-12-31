<?php

namespace App\Exceptions;

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
            return response()->json([
                'ok' => false,
                'message' => 'Too many requests',
                'error_code' => 'RATE_LIMIT',
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
}
