package main

import "../lib/ecs"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:fmt"
import rl "vendor:raylib"

Player :: struct {}

Runner :: struct {
	position:  vec3,
	direction: vec3,
	velocity:  vec3,
	speed:     f32,
	sprint:    f32,
	on_ground: bool,
	height:    f32,
    jump: f32,
}

player_move_system :: proc(w: ^ecs.World(Component)) {
    player_entity, runner, ok := get_player(w)
    if !ok do return

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
    speed := runner.speed
    if rl.IsKeyDown(.LEFT_SHIFT) && vector_in_sprint_range(mov, runner.direction) {
        if ok do speed += runner.sprint
    }

    // lower movement control when in air
    if !runner.on_ground {
        mov *= 0.5
        runner.position.xz += mov.xz * speed * w.delta
    } else {
        runner.velocity.xz = mov.xz * speed
    }


    ecs.set_component(w, player_entity, runner)
}

apply_velocity_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		runner.position += runner.velocity * w.delta

		ecs.set_component(w, &e, runner)
	}
}

FALL_G :: 0.0098
MAX_FALL_VEL :: 100
runner_fall_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

		if !runner.on_ground {
			runner.velocity.y -= FALL_G
			runner.velocity.y = rl.Clamp(runner.velocity.y, -MAX_FALL_VEL, +MAX_FALL_VEL)
		}

		ecs.set_component(w, &e, runner)
	}
}

fake_ground_system :: proc(w: ^ecs.World(Component)) {
	for &e in w.entities {
		if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

        if runner.position.y - runner.height <= 0 {
            runner.on_ground = true
            runner.position.y = runner.height
            // runner.velocity.y = 0
        } else {
            runner.on_ground = false
        }

		ecs.set_component(w, &e, runner)
	}
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
