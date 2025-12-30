<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;

class AuthController extends Controller
{
    public function register(Request $req)
    {
        $req->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6'
        ]);

        $user = User::create([
            'name' => $req->name,
            'email' => $req->email,
            'password' => bcrypt($req->password)
        ]);

        $token = $user->createToken('api')->plainTextToken;

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
        $token = $user->createToken('api')->plainTextToken;

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

        return response()->json(['status' => 'saved']);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();
        if ($token) {
            $token->delete();
        }

        return response()->json([
            'ok' => true,
            'message' => 'Logged out',
            'data' => new \stdClass(),
        ]);
    }
}
