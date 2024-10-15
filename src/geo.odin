package main

import "core:math/linalg"
import rl "vendor:raylib"

DEG2RAD :: linalg.RAD_PER_DEG
RAD2DEG :: linalg.DEG_PER_RAD

vec2 :: [2]f32
vec3 :: [3]f32

get_right :: proc(v: vec3) -> vec3 {
    // v.z == flat.y
    flat: vec2 = v.xz
    flat = rl.Vector2Normalize(flat)
    flat = rl.Vector2Rotate(flat, 90*DEG2RAD)

    return {flat.x, 0, flat.y}
}

flatten_to_vec2 :: proc(v: vec3) -> vec2 {
    flat: vec2 = v.xz
    return rl.Vector2Normalize(flat)
}

get_foreward :: proc(v: vec3) -> vec3 {
    // v.z == flat.y
    flat: vec2 = v.xz
    flat = rl.Vector2Normalize(flat)

    return {flat.x, 0, flat.y}
}
