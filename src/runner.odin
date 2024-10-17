package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"

Player :: struct {}

Runner :: struct {
	position:  vec3,
	direction: vec3,
    velocity:  vec3,
	speed:     f32,
	sprint:    f32,
	on_ground: bool,
}

FALL_G :: 0.0098
MAX_FALL_VEL :: 4
runner_fall_system :: proc(w: ^ecs.World(Component)) {
    for &e in w.entities {
        if !ecs.has_components(e, Runner) do continue
        runner := ecs.must_get_component(w^, e.id, Runner)
        fmt.println("hello fall")

        if runner.on_ground {
            runner.velocity.y = 0
        } else {
            runner.velocity.y -= FALL_G
            runner.velocity.y = rl.Clamp(runner.velocity.y, -MAX_FALL_VEL, +MAX_FALL_VEL)
        }

        ecs.set_component(w, &e, runner)
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
