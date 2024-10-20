package main

import "core:math/linalg"
import rl "vendor:raylib"

DEG2RAD :: linalg.RAD_PER_DEG
RAD2DEG :: linalg.DEG_PER_RAD

vec2 :: [2]f32
vec3 :: [3]f32

UP :: vec3{0,1,0}

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

quaternion_from_vec3 :: proc(v: vec3) -> quaternion128 {
    q := rl.QuaternionFromMatrix(rl.MatrixLookAt({}, v, UP))
    q = q * rl.QuaternionFromEuler(0, -90*DEG2RAD, 0)

    axis, angle := rl.QuaternionToAxisAngle(q);
    axis = rl.Vector3RotateByAxisAngle(axis, UP, -90*DEG2RAD);

    return rl.QuaternionFromAxisAngle(axis, -angle);
}
