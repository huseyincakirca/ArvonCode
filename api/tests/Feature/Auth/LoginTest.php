<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_and_get_token(): void
    {
        $password = 'secure-pass';

        User::factory()->create([
            'email' => 'login@example.com',
            'password' => Hash::make($password),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'login@example.com',
            'password' => $password,
        ], [
            'Accept' => 'application/json',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
            ])
            ->assertJsonStructure([
                'ok',
                'message',
                'data' => [
                    'user',
                    'token',
                ],
            ]);

        $this->assertIsString($response->json('data.token'));
        $this->assertNotEmpty($response->json('data.token'));
    }

    public function test_login_with_wrong_password_fails(): void
    {
        User::factory()->create([
            'email' => 'wrong-pass@example.com',
            'password' => Hash::make('right-password'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'wrong-pass@example.com',
            'password' => 'incorrect-password',
        ], [
            'Accept' => 'application/json',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'ok' => false,
                'message' => 'Invalid credentials',
            ]);

        $this->assertSame([], $response->json('data'));
    }
}
