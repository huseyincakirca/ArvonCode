<?php

namespace Tests\Feature\Auth;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegisterTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_token(): void
    {
        $payload = [
            'name' => 'Test User',
            'email' => 'register@example.com',
            'password' => 'password123',
        ];

        $response = $this->postJson('/api/register', $payload, [
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
        $this->assertEquals($payload['email'], $response->json('data.user.email'));
    }
}
