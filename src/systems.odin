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

    SENSITIVITY :: 0.002
    player.direction = rl.Vector3RotateByAxisAngle(player.direction, {0,1,0}, -mouse.x * SENSITIVITY)
    player.direction = rl.Vector3RotateByAxisAngle(player.direction, get_right(player.direction), -mouse.y * SENSITIVITY)

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

player_move_system :: proc(w: ^ecs.World(Component)) {
    player_entity, player, ok := get_player(w)
    if !ok do return

    speed := player.speed

    if rl.IsKeyDown(.LEFT_SHIFT) {
        sprint, ok := ecs.get_component(w^, player_entity.id, Sprint)
        if ok do speed += sprint.mul
    }

    mov: vec3

    if rl.IsKeyDown(.W) {
        mov += get_foreward(player.direction)
    }
    if rl.IsKeyDown(.S) {
        mov -= get_foreward(player.direction)
    }
    if rl.IsKeyDown(.D) {
        mov += get_right(player.direction)
    }
    if rl.IsKeyDown(.A) {
        mov -= get_right(player.direction)
    }

    mov = rl.Vector3Normalize(mov)
    if vector_in_sprint_range(mov, player.direction) {
        player.position += mov * speed * w.delta
    } else {
        player.position += mov * w.delta
    }

    ecs.set_component(w, player_entity, player)
}

vector_in_sprint_range :: proc(mov: vec3, look: vec3) -> bool {
    flat_look := flatten_to_vec2(look)
    flat_mov := flatten_to_vec2(mov)

    // TODO:
    return true
}

move_camera_by_buttons_system :: proc(w: ^ecs.World(Component)) {
    if !mouse do return

    player_entity, player, ok := get_player(w)
    if !ok do return

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

get_player :: proc(w: ^ecs.World(Component)) -> (^ecs.Entity, Player, bool) {
	for &e in w.entities {
		if ecs.has_components(e, Player) {
            player_cmp := ecs.must_get_component(w^, e.id, Player)
            return &e, player_cmp, true
		}
	}

    return nil, Player{}, false
}
