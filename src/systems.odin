package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:math/linalg"

mouse_enabled := false

common_system :: proc(w: ^ecs.World(Component)) {
    if !mouse_enabled {
        rl.DisableCursor()
    } 
    if rl.IsKeyReleased(.TAB) {
        mouse_enabled = !mouse_enabled
        if mouse_enabled {
            rl.EnableCursor()
        } 
    }
}

player_camera_system :: proc(w: ^ecs.World(Component)) {
    // Find the player and camera 
    camera_entity, camera, camera_found := get_camera(w)
    player_entity, runner, player_found := get_player(w)

    if !player_found || !camera_found do return

    // Logic here
    mouse := rl.GetMouseDelta()

    if !mouse_enabled {
        SENSITIVITY :: 0.002
        runner.direction = rl.Vector3RotateByAxisAngle(runner.direction, {0,1,0}, -mouse.x * SENSITIVITY)
        runner.direction = rl.Vector3RotateByAxisAngle(runner.direction, get_right(runner.direction), -mouse.y * SENSITIVITY)
    }

    camera.position = runner.position
    camera.target = runner.position + runner.direction

    ecs.set_component(w, camera_entity, camera)
    ecs.set_component(w, player_entity, runner)
}

draw_scene_system :: proc(w: ^ecs.World(Component)) {
    rl.DrawGrid(10, 1)

    rl.DrawLine3D({-5,0,0}, {5,0,0}, rl.RED)
    rl.DrawLine3D({0,-5,0}, {0,5,0}, rl.GREEN)
    rl.DrawLine3D({0,0,-5}, {0,0,5}, rl.BLUE)
    rl.DrawSphere({5,0,0}, 0.1, rl.RED)
    rl.DrawSphere({0,5,0}, 0.1, rl.GREEN)
    rl.DrawSphere({0,0,5}, 0.1, rl.BLUE)
}


vector_in_sprint_range :: proc(mov: vec3, look: vec3) -> bool {
    flat_look := flatten_to_vec2(look)
    flat_mov := flatten_to_vec2(mov)

    // TODO:
    return true
}

// move_camera_by_buttons_system :: proc(w: ^ecs.World(Component)) {
//     if !mouse do return
//
//     player_entity, player, ok := get_player(w)
//     if !ok do return
//
//     imgui.Begin("camera control")
//     imgui.Button("left", {50, 30})
//     if imgui.IsItemActive() {
//         player.position.x += 0.3
//     }
//     imgui.End()
//
//     ecs.set_component(w, player_entity, player)
// }

get_camera :: proc(w: ^ecs.World(Component)) -> (^ecs.Entity, rl.Camera3D, bool) {
	for &e in w.entities {
		if ecs.has_components(e, rl.Camera3D) {
            camera := ecs.must_get_component(w^, e.id, rl.Camera3D)
            return &e, camera, true
		}
	}

    return nil, rl.Camera3D{}, false
}

get_player :: proc(w: ^ecs.World(Component)) -> (^ecs.Entity, Runner, bool) {
	for &e in w.entities {
		if ecs.has_components(e, Player, Runner) {
            runner := ecs.must_get_component(w^, e.id, Runner)
            return &e, runner, true
		}
	}

    return nil, Runner{}, false
}

debug_player_system :: proc(w: ^ecs.World(Component)) {
    player_entity, player, ok := get_player(w)
    if !ok do return

    info := fmt.caprint(
        "pos: ", player.position, "\n",
        "dir: ", player.direction, "\n",
        "vel: ", player.velocity, "\n",
        sep = "",
    )
    imgui.Begin("player")

    imgui.SliderFloat("jump", &player.jump, 1, 15)
    imgui.Text(info)
    imgui.End()

    ecs.set_component(w, player_entity, player)
}
