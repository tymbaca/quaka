package main

import "../lib/ecs"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:fmt"
import rl "vendor:raylib"

Player :: struct {}

Runner :: struct {
	position:   vec3,
	direction:  vec3,
	velocity:   vec3,
	speed:      f32,
	sprint:     f32,
	on_ground:  bool,
	is_running: bool,
	height:     f32,
	jump:       f32,
}

player_move_system :: proc(w: ^ecs.World(Component)) {
	player_entity, runner, ok := get_player(w)
	if !ok do return

	if runner.on_ground {
		player_move_on_ground(w, &runner)
	} else {
		player_move_in_air(w, &runner)
	}

	ecs.set_component(w, player_entity, runner)
}


player_move_on_ground :: proc(w: ^ecs.World(Component), runner: ^Runner) {
	ACCELERATION :: 30
	mov: vec3

	if rl.IsKeyDown(.W) {
		mov += get_foreward(runner.direction)
	}
	if rl.IsKeyDown(.S) {
		mov -= get_foreward(runner.direction)
	}
	if rl.IsKeyDown(.D) {
		mov += get_right(runner.direction)
	}
	if rl.IsKeyDown(.A) {
		mov -= get_right(runner.direction)
	}
	mov = rl.Vector3Normalize(mov)

	if rl.Vector3Length(mov) > 0 {
		runner.is_running = true
	} else {
		runner.is_running = false
	}

	// Clamp value by speed, if on the ground
	speed := runner.speed
	if rl.IsKeyDown(.LEFT_SHIFT) && vector_in_sprint_range(mov, runner.direction) {
		speed *= runner.sprint
	}

	runner.velocity.xz += mov.xz * ACCELERATION * w.delta
	runner.velocity.xz = rl.Vector2ClampValue(runner.velocity.xz, 0, speed)
}

player_move_in_air :: proc(w: ^ecs.World(Component), runner: ^Runner) {
	AIR_CONTROL :: 5
	mov: vec3

	if rl.IsKeyDown(.W) {
		mov += get_foreward(runner.direction)
	}
	if rl.IsKeyDown(.S) {
		mov -= get_foreward(runner.direction)
	}
	if rl.IsKeyDown(.D) {
		mov += get_right(runner.direction)
	}
	if rl.IsKeyDown(.A) {
		mov -= get_right(runner.direction)
	}

	mov = rl.Vector3Normalize(mov)
	runner.velocity.xz += mov.xz * AIR_CONTROL * w.delta

	// clamp in air speed by it's maximum sprint speed
	runner.velocity.xz = rl.Vector2ClampValue(runner.velocity.xz, 0, runner.speed * runner.sprint)
}

GROUND_FRICTION :: 5
ground_friction_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		if runner.on_ground && !runner.is_running {
			// stop if speed is too low
			if rl.Vector2Length(runner.velocity.xz) < 0.001 {
				runner.velocity.xz *= 0
				ecs.set_component(w, &e, runner)
				continue
			}

            // apply friction
			fricton := 1 - (GROUND_FRICTION * w.delta)
			runner.velocity.xz *= fricton

			// if speed is already slow - slow down more
			if rl.Vector2Length(runner.velocity.xz) < 1 {
				runner.velocity.xz *= fricton
			}
			ecs.set_component(w, &e, runner)
		}
	}
}

apply_velocity_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		runner.position += runner.velocity * w.delta

		ecs.set_component(w, &e, runner)
	}
}

FALL_G :: 9.8
MAX_FALL_VEL :: 100
gravity_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		if !runner.on_ground {
			runner.velocity.y -= FALL_G * w.delta
			runner.velocity.y = rl.Clamp(runner.velocity.y, -MAX_FALL_VEL, +MAX_FALL_VEL)
		} else {
			runner.velocity.y = 0
		}

		ecs.set_component(w, &e, runner)
	}
}

is_on_ground_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		if is_on_ground(w, runner) {
			runner.on_ground = true
			runner.position.y = runner.height
		} else {
			runner.on_ground = false
		}

		ecs.set_component(w, &e, runner)
	}
}

is_on_ground :: proc(w: ^ecs.World(Component), runner: Runner) -> bool {
	// TODO
	return runner.position.y - runner.height <= 0
}

jump_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner, Player) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		if rl.IsKeyPressed(.SPACE) && runner.on_ground {
			runner.velocity.y = runner.jump
		}

		ecs.set_component(w, &e, runner)
	}
}
