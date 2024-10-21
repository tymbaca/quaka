package main

import "../lib/ecs"
import rl "vendor:raylib"

MAX_LEVEL_SIDE :: 64
BLOCK_SIZE :: 4

Level :: struct {
    blocks: [MAX_LEVEL_SIDE][MAX_LEVEL_SIDE][MAX_LEVEL_SIDE]bool
}

LevelBlock :: struct {
    type: enum {
        NONE,
        ROCK,
    },
    // TODO: friction
}

// collide_blocks_system :: proc(w: ^ecs.World(Component)) { 
//     player_e, player, ok :=  get_player(w)
//     if ok {
//        
//     }
// }
