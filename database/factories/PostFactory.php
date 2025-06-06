<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => 2, // usersテーブルにidカラムの値が2のユーザーが存在することが前提
            'title' => fake()->realText(20, 5),
            'content' => fake()->realText(200, 5)
        ];
    }
}
