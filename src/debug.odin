package main

import "core:fmt"
import "../lib/ecs"
import rl "vendor:raylib"
import imgui "../lib/imgui"
import imgui_rl "../lib/imgui/imgui_impl_raylib"
import "core:math/linalg"

debug_player_system :: proc(w: ^ecs.World(Component)) {
    player_entity, player, ok := get_player(w)
    if !ok do return

    info := fmt.caprint(
        "pos: ", player.position, "\n",
        "dir: ", player.direction, "\n",
        "vel: ", player.velocity, "\n",
        "speed: ", rl.Vector3Length(player.velocity), "\n",
        "hor_speed: ", rl.Vector2Length(player.velocity.xz), "\n",
        sep = "",
    )
    imgui.Begin("player")

    imgui.SliderFloat("jump", &player.jump, 1, 15, flags = {.NoInput})
    imgui.SliderFloat("height", &player.height, 0, 5, flags = {.NoInput})
    imgui.SliderFloat("speed", &player.speed, 0, 5, flags = {.NoInput})
    imgui.SliderFloat3("weapon offset", &WEAPON_OFFSET, -5, 5, flags = {.NoInput})
    //
    if imgui.CollapsingHeader("entities") {
        imgui.TextWrapped(fmt.caprint(w.entities))
    }

    imgui.Text(info)

    imgui.End()

    ecs.update_component(w, player_entity.id, player)
}
