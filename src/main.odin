package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"


/*
TODO:
- preallocate entities/cmp
- private funcs in ecs (update_time)
*/

UPDATE_COLLECTION :: "update"
DRAW3D_COLLECTION :: "draw-3d"
UPDATE_PRE_2D_COLLECTION :: "update-pre-2d"
DRAW2D_COLLECTION :: "draw-2d"

main :: proc() {
    rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
    rl.InitWindow(1200, 800, "quaka")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    imgui.CreateContext(nil)
    defer imgui.DestroyContext(nil)
    imgui_rl.init()
    defer imgui_rl.shutdown()
    imgui_rl.build_font_atlas()


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
    // SYSTEM REGISTRATION
    ecs.register_systems(&world, player_camera_system, collection = UPDATE_COLLECTION)
    ecs.register_systems(&world, draw_scene_system, collection = DRAW3D_COLLECTION)
    ecs.register_systems(&world, move_camera_by_buttons_system, collection = UPDATE_PRE_2D_COLLECTION)

    for !rl.WindowShouldClose() {
        // YOUR CODE HERE
        ecs.update_time(&world)
        ecs.update_collection(&world, UPDATE_COLLECTION)
        fmt.println(world)

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        imgui_rl.process_events()
        imgui_rl.new_frame()
        imgui.NewFrame()


        rl.BeginMode3D(ecs.get_component(world, camera_entity.id, rl.Camera3D))
        // YOUR CODE HERE
        ecs.update_collection(&world, DRAW3D_COLLECTION)
        rl.EndMode3D()

        // YOUR CODE HERE
        ecs.update_collection(&world, UPDATE_PRE_2D_COLLECTION)
        ecs.update_collection(&world, DRAW2D_COLLECTION)
        imgui.Button("click me", {100, 40})

        imgui.ShowDemoWindow(nil)
        imgui.Render()
        imgui_rl.render_draw_data(imgui.GetDrawData())
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

draw_scene_system :: proc(w: ^ecs.World(Component)) {
    rl.DrawGrid(10, 1)
}

move_camera_by_buttons_system :: proc(w: ^ecs.World(Component)) {
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
