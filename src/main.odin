package main

import "../lib/ecs"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:fmt"
import rl "vendor:raylib"


/*
TODO:
- preallocate entities/cmp
- private funcs in ecs (update_time)
- use world temp_allocator? to free all between frames
- limit up/down look direction
- `update_component` with only id
- has_component optional `not` arg
*/

Component :: union {
	Player,
	Runner,
    Weapon,
    Bullet,
	rl.Camera3D,
}

UPDATE_COLLECTION :: "update"
DRAW3D_COLLECTION :: "draw-3d"
UPDATE_PRE_2D_COLLECTION :: "update-pre-2d"
DRAW2D_COLLECTION :: "draw-2d"

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1200, 800, "quaka")
	defer rl.CloseWindow()
	rl.DisableCursor()
	// rl.SetTargetFPS(60)

	imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)
	imgui_rl.init()
	defer imgui_rl.shutdown()
	imgui_rl.build_font_atlas()


	world := ecs.new_world(Component)
	// for _ in 0..<10000 {
	//     ecs.create_entity(
	//         &world,
	//         Player{},
	//         Runner {
	//             position = {1, 1, 1},
	//             direction = rl.Vector3Normalize({-1, -1, -1}),
	//             speed = 2,
	//             sprint = 2,
	//             height = 0.5,
	//             jump = 3.4,
	//         },
	//     )
	// }
    
	ecs.create_entity(
		&world,
		Player{},
		Runner {
			position = {1, 1, 1},
			direction = rl.Vector3Normalize({-1, -1, -1}),
			speed = 2.5,
			sprint = 1.3,
			height = 0.5,
			jump = 3.4,
		},
		rl.Camera3D {
			up = {0, 1, 0},
			fovy = 80,
			projection = .PERSPECTIVE,
			position = {1, 1, 1},
			target = {0, 0, 0},
		},
        Weapon{
            model = rl.LoadModel("assets/weapon.obj"),
            bullet_type = .ROCKET,
            max_ammo = 30,
            ammo = 30,
        }
	)
	// SYSTEM REGISTRATION
	ecs.register_systems(
		&world,
		player_camera_system,
		common_system,
		player_move_system,
		jump_system,
		apply_velocity_system,
		is_on_ground_system,
		ground_friction_system,
		gravity_system,
        weapon_fire_system,
        bullet_system,
		collection = UPDATE_COLLECTION,
	)
	ecs.register_systems(&world, draw_scene_system, draw_weapon_system, draw_bullet_system, collection = DRAW3D_COLLECTION)
	ecs.register_systems(&world, debug_player_system, collection = UPDATE_PRE_2D_COLLECTION)

	for !rl.WindowShouldClose() {
		// YOUR CODE HERE
		ecs.update_time(&world)
		ecs.update_collection(&world, UPDATE_COLLECTION)

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		imgui_rl.process_events()
		imgui_rl.new_frame()
		imgui.NewFrame()

		_, cam, ok := get_camera(&world)
		if !ok do panic("shit no camera found")
		rl.BeginMode3D(cam)
		// YOUR CODE HERE
		ecs.update_collection(&world, DRAW3D_COLLECTION)
		rl.EndMode3D()

		// YOUR CODE HERE
		ecs.update_collection(&world, UPDATE_PRE_2D_COLLECTION)
		ecs.update_collection(&world, DRAW2D_COLLECTION)
		rl.DrawFPS(10, 10)

		imgui.Render()
		imgui_rl.render_draw_data(imgui.GetDrawData())
		rl.EndDrawing()
	}
}
