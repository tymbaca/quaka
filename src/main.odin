package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"

/*
TODO:
- preallocate entities/cmp
- private funcs in ecs (update_time)
*/

main :: proc() {
    rl.InitWindow(1200, 800, "quaka")
    rl.SetTargetFPS(60)

    camera := rl.Camera3D{
        up = {0,1,0},
        fovy = 80,
        projection = .PERSPECTIVE,
        position = {1,1,1},
        target = {0,0,0},
    }

    world := ecs.new_world(Component)
    ecs.create_entity(&world, Player{
        position = {1,1,1},
        direction = rl.Vector3Normalize({-1,-1,-1}),
    })
    camera_entity := ecs.create_entity(&world, camera)
    ecs.register_systems(&world, player_camera_system)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()

        ecs.update(&world)
        fmt.println(world)

        rl.BeginMode3D(ecs.get_component(world, camera_entity.id, rl.Camera3D))

        rl.EndMode3D()

        rl.EndDrawing()
    }
}

Component :: union {
    Player,
    rl.Camera3D,
}

Player :: struct {
    position: [3]f32,
    direction: [3]f32,
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

    fmt.println("hello from camera system")
    
    if camera_entity == nil || player_entity == nil {
        return
    }

    camera := ecs.must_get_component(w^, camera_entity.(^ecs.Entity).id, rl.Camera3D)
    player := ecs.must_get_component(w^, player_entity.(^ecs.Entity).id, Player)

    // Logic here
    camera.position = player.position
    camera.target = player.position + player.direction

    ecs.set_component(w, camera_entity.(^ecs.Entity), camera)
    ecs.set_component(w, player_entity.(^ecs.Entity), player)
}
