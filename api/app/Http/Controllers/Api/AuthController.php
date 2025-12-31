<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function register(Request $req)
    {
        $normalizedEmail = strtolower((string) $req->input('email'));
        $req->merge(['email' => $normalizedEmail]);

        $req->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6|confirmed',
        ]);

        $user = User::create([
            'name' => $req->name,
            'email' => $normalizedEmail,
            'password' => bcrypt($req->password)
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'ok' => true,
            'message' => 'Register successful',
            'data' => [
                'user' => $user,
                'token' => $token,
            ],
        ]);
    }

    public function login(Request $req)
    {
        if (!Auth::attempt($req->only('email', 'password'))) {
            return response()->json([
                'ok' => false,
                'message' => 'Invalid credentials',
                'data' => new \stdClass(),
            ], 401);
        }

        /** @var \App\Models\User $user */
        $user = Auth::user();
        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'ok' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user,
                'token' => $token,
            ],
        ]);
    }

    public function savePushId(Request $req)
    {
        $req->validate([
            'push_id' => 'required'
        ]);

        /** @var \App\Models\User $user */
        $user = auth()->user();
        $user->push_id = $req->push_id;
        $user->save();

        return response()->json([
            'ok' => true,
            'message' => 'Push id saved',
            'data' => new \stdClass(),
        ]);
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        $token = $user?->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        } elseif ($request->bearerToken()) {
            $personalToken = PersonalAccessToken::findToken($request->bearerToken());
            if ($personalToken) {
                $personalToken->delete();
            }
        }

        if ($request->hasSession()) {
            auth()->guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        }

        return response()->json([
            'ok' => true,
            'message' => 'Logged out',
            'data' => new \stdClass(),
        ]);
    }
}
