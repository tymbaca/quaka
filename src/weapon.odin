package main

import "../lib/ecs"
import "core:fmt"
import rl "vendor:raylib"

Weapon :: struct {
	model:       rl.Model,
	bullet_type: Bullet_Type,
	max_ammo:    int,
	ammo:        int,
}

Bullet :: struct {
	type:     Bullet_Type,
	position: vec3,
	velocity: vec3,
	ttl:      f32, // sec
}

Bullet_Type :: enum {
	BASIC,
	ROCKET,
}

WEAPON_OFFSET := vec3{0, -0.065, 0}

weapon_fire_system :: proc(w: ^ecs.World(Component)) {
	if mouse_enabled do return

	for e in w.entities {
		if !ecs.has_components(e, Player, Runner, Weapon) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)
		weapon := ecs.must_get_component(w^, e.id, Weapon)

		if rl.IsMouseButtonPressed(.LEFT) {
			weapon_fire(w, &weapon, runner)
		}

		ecs.update_component(w, e.id, runner)
		ecs.update_component(w, e.id, weapon)
	}
}

weapon_fire :: proc(world: ^ecs.World(Component), weapon: ^Weapon, runner: Runner) {
	if weapon.ammo <= 0 do return
	ecs.create_entity(
		world,
		Bullet{type = weapon.bullet_type, ttl = 2, velocity = runner.direction * 6, position = runner.position},
	)
	// weapon.ammo -= 1
}

bullet_system :: proc(w: ^ecs.World(Component)) {
	for e in w.entities {
		if !ecs.has_components(e, Bullet) do continue
		bullet := ecs.must_get_component(w^, e.id, Bullet)

		switch bullet.type {
		case .BASIC:
			basic_bullet_handle(w, e.id, bullet)
		case .ROCKET:
			rocket_handle(w, e.id, bullet)
		}
	}
}

basic_bullet_handle :: proc(w: ^ecs.World(Component), id: int, bullet: Bullet) {
	bullet := bullet
	if bullet.ttl <= 0 {
		ecs.remove_entity(w, id)
		return
	}

	bullet.position += bullet.velocity * w.delta
	bullet.ttl -= w.delta

	ecs.update_component(w, id, bullet)
}

rocket_handle :: proc(w: ^ecs.World(Component), id: int, bullet: Bullet) {
	bullet := bullet
	if rocket_must_explode(w, bullet) {
        rocket_push_runners_away(w, bullet)
		ecs.remove_entity(w, id)
		return
	}

	bullet.position += bullet.velocity * w.delta
	bullet.ttl -= w.delta

	ecs.update_component(w, id, bullet)
}

rocket_must_explode :: proc(w: ^ecs.World(Component), bullet: Bullet) -> bool {
	if bullet.ttl <= 0 do return true

	if is_colliding(w, bullet.position) do return true

	return false
}

EXPLODE_PUSH_DISTANCE :: 3
EXPLODE_PUSH_POWER :: 8
rocket_push_runners_away :: proc(w: ^ecs.World(Component), bullet: Bullet) {
    for e in w.entities {
        if !ecs.has_components(e, Runner) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)

        // get vector from bullet to runnet
        push_vector := runner.position - bullet.position

        distance := rl.Vector3Length(push_vector)
        if distance > EXPLODE_PUSH_DISTANCE do continue
        push_direction := rl.Vector3Normalize(push_vector)

        // closer the runnes - bigger the push factor
        factor := 1 - (distance / EXPLODE_PUSH_DISTANCE)
        push := rl.Lerp(0, EXPLODE_PUSH_POWER, factor)

        runner.velocity += push_direction * push

        ecs.update_component(w, e.id, runner)
    }
}

BULLET_COLLIDER_RADIUS :: 0.05
is_colliding :: proc(w: ^ecs.World(Component), position: vec3) -> bool {
    _, level, ok := get_level(w)
    if ok {
        for block in level.blocks {
            if rl.CheckCollisionBoxSphere(block.box, position, BULLET_COLLIDER_RADIUS) {
                return true
            }
        }
    }

	return false
}

draw_bullet_system :: proc(w: ^ecs.World(Component)) {
	for e in w.entities {
		if !ecs.has_components(e, Bullet) do continue
		bullet := ecs.must_get_component(w^, e.id, Bullet)

		rl.DrawSphere(bullet.position, 0.05, rl.RED)

		ecs.update_component(w, e.id, bullet)
	}
}

draw_weapon_system :: proc(w: ^ecs.World(Component)) {
	for e in w.entities {
		if !ecs.has_components(e, Runner, Weapon) do continue
		runner := ecs.must_get_component(w^, e.id, Runner)
		weapon := ecs.must_get_component(w^, e.id, Weapon)

		q := quaternion_from_vec3(runner.direction)
		weapon.model.transform = rl.QuaternionToMatrix(q)
		rl.DrawModel(weapon.model, runner.position + WEAPON_OFFSET, 1, rl.WHITE)

		ecs.update_component(w, e.id, runner)
		ecs.update_component(w, e.id, weapon)
	}
}
