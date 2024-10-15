package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:math/linalg"

mouse := false

common_system :: proc(w: ^ecs.World(Component)) {
    if rl.IsKeyReleased(.TAB) {
        mouse = !mouse
        if mouse {
            rl.EnableCursor()
        } else {
            rl.DisableCursor()
        } 
    }
}

player_camera_system :: proc(w: ^ecs.World(Component)) {
    // Find the player and camera 
    camera_entity: Maybe(^ecs.Entity)
    player_entity: Maybe(^ecs.Entity)

	for &e in w.entities {
		if ecs.has_components(e, rl.Camera3D) {
            camera_entity = &e
		}
		if ecs.has_components(e, Player) {
            player_entity = &e
		}
	}
    
    if camera_entity == nil || player_entity == nil {
        return
    }

    camera := ecs.must_get_component(w^, camera_entity.(^ecs.Entity).id, rl.Camera3D)
    player := ecs.must_get_component(w^, player_entity.(^ecs.Entity).id, Player)

    // Logic here
    mouse := rl.GetMouseDelta()

    SENSITIVITY :: 0.01
    player.direction = rl.Vector3RotateByAxisAngle(player.direction, {0,1,0}, -mouse.x * SENSITIVITY)
    fmt.println(get_right_axis(player.direction), mouse.y)
    player.direction = rl.Vector3RotateByAxisAngle(player.direction, get_right_axis(player.direction), -mouse.y * SENSITIVITY)

    camera.position = player.position
    camera.target = player.position + player.direction

    ecs.set_component(w, camera_entity.(^ecs.Entity), camera)
    ecs.set_component(w, player_entity.(^ecs.Entity), player)
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

move_camera_by_buttons_system :: proc(w: ^ecs.World(Component)) {
    if !mouse do return

    player_entity, ok := get_player(w)
    if !ok do return

    player := ecs.must_get_component(w^, player_entity.id, Player)

    imgui.Begin("camera control")
    imgui.Button("left", {50, 30})
    if imgui.IsItemActive() {
        player.position.x += 0.3
    }
    imgui.End()

    ecs.set_component(w, player_entity, player)
}

get_camera :: proc(w: ^ecs.World(Component)) -> (^ecs.Entity, bool) #optional_ok {
	for &e in w.entities {
		if ecs.has_components(e, rl.Camera3D) {
            return &e, true
		}
	}

    return nil, false
}

get_player :: proc(w: ^ecs.World(Component)) -> (^ecs.Entity, bool) #optional_ok {
	for &e in w.entities {
		if ecs.has_components(e, Player) {
            return &e, true
		}
	}

    return nil, false
}
