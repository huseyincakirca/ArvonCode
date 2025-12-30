<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserPushTokenRequest;
use App\Models\UserPushToken;

class UserPushTokenController extends Controller
{
    public function store(StoreUserPushTokenRequest $request)
    {
        $data = $request->validated();
        $user = $request->user();

        $existing = UserPushToken::where('token', $data['token'])->first();

        if ($existing) {
            $existing->user_id = $user->id;
            $existing->platform = $data['platform'];

            if ($existing->isDirty()) {
                $existing->save();
            } else {
                $existing->touch();
            }

            return response()->json([
                'ok' => true,
                'message' => 'Push token saved',
                'data' => null,
            ]);
        }

        UserPushToken::create([
            'user_id' => $user->id,
            'token' => $data['token'],
            'platform' => $data['platform'],
        ]);

        return response()->json([
            'ok' => true,
            'message' => 'Push token saved',
            'data' => null,
        ]);
    }
}
