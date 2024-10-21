package main

import "../lib/ecs"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

MAX_LEVEL_SIDE :: 64
BLOCK_SIZE :: 4

Level :: struct {
    blocks: []Level_Block
}

Level_Block :: struct {
    type: enum {
        NONE,
        ROCK,
    },
    box: rl.BoundingBox,
    // TODO: friction
}

draw_level_system :: proc(w: ^ecs.World(Component)) {
    level: Level
    for e in w.entities {
        if ecs.has_components(e, Level) {
            level = ecs.must_get_component(w^, e.id, Level)
            break
        }
    }

    for block in level.blocks {
        draw_level_block(block)
    }
}

draw_level_block :: #force_inline proc(block: Level_Block) {
    switch block.type {
    case .NONE:
        return
    case .ROCK:
        rl.DrawBoundingBox(block.box, rl.BROWN)
    }
}

// DrawTexturePoly :: proc() 

// collide_blocks_system :: proc(w: ^ecs.World(Component)) { 
//     player_e, player, ok :=  get_player(w)
//     if ok {
//        
//     }
// }
