<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('public_request_logs', function (Blueprint $table) {
            $table->id();
            $table->string('endpoint', 191);
            $table->string('method', 10);
            $table->string('ip', 64)->nullable();
            $table->string('user_agent', 255)->nullable();

            $table->string('vehicle_uuid', 255)->nullable();
            $table->unsignedBigInteger('vehicle_id')->nullable(); // vehicles.id (numeric) bulunursa

            $table->boolean('ok')->default(false);
            $table->unsignedSmallInteger('status_code')->nullable();
            $table->string('error_code', 64)->nullable(); // örn: VEHICLE_NOT_FOUND / RATE_LIMIT / VALIDATION
            $table->string('error_message', 255)->nullable();

            $table->timestamps();

            $table->index(['ip']);
            $table->index(['vehicle_uuid']);
            $table->index(['vehicle_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('public_request_logs');
    }
};
