<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;
use Tests\TestCase;

class LogoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_logout_and_token_is_invalidated(): void
    {
        config()->set('sanctum.stateful', []);
        config()->set('sanctum.guard', []);
        $this->withoutMiddleware(EnsureFrontendRequestsAreStateful::class);
        $password = 'logout-password';

        User::factory()->create([
            'email' => 'logout@example.com',
            'password' => Hash::make($password),
        ]);

        $loginResponse = $this->postJson('/api/login', [
            'email' => 'logout@example.com',
            'password' => $password,
        ], [
            'Accept' => 'application/json',
        ]);

        $token = $loginResponse->json('data.token');

        $response = $this->withServerVariables([
            'HTTP_HOST' => 'api-token.test',
        ])->postJson('/api/logout', [], [
            'Accept' => 'application/json',
            'Authorization' => "Bearer {$token}",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Logged out',
            ]);
        $this->assertSame([], $response->json('data'));

        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->defaultCookies = [];
        $this->unencryptedCookies = [];
        app('auth')->forgetGuards();

        $protectedResponse = $this->withServerVariables([
            'HTTP_HOST' => 'api-token.test',
        ])->getJson('/api/vehicles', [
            'Accept' => 'application/json',
            'Authorization' => "Bearer {$token}",
        ]);

        $protectedResponse->assertStatus(401);
    }

    public function test_logout_is_not_allowed_without_valid_token(): void
    {
        config()->set('sanctum.stateful', []);
        config()->set('sanctum.guard', []);
        $this->withoutMiddleware(EnsureFrontendRequestsAreStateful::class);

        $password = 'double-logout';

        User::factory()->create([
            'email' => 'doublelogout@example.com',
            'password' => Hash::make($password),
        ]);

        $loginResponse = $this->postJson('/api/login', [
            'email' => 'doublelogout@example.com',
            'password' => $password,
        ], [
            'Accept' => 'application/json',
        ]);

        $token = $loginResponse->json('data.token');

        $first = $this->postJson('/api/logout', [], [
            'Accept' => 'application/json',
            'Authorization' => "Bearer {$token}",
        ]);

        $first->assertStatus(200)
            ->assertJson([
                'ok' => true,
                'message' => 'Logged out',
            ]);

        $this->defaultCookies = [];
        $this->unencryptedCookies = [];
        app('auth')->forgetGuards();

        $second = $this->postJson('/api/logout', [], [
            'Accept' => 'application/json',
            'Authorization' => "Bearer {$token}",
        ]);

        $second->assertStatus(401)
            ->assertJson([
                'ok' => false,
                'error_code' => 'UNAUTHENTICATED',
            ]);
    }
}
