extends RefCounted

const Rules = preload("res://world/simulation/world_rules.gd")
const EntityIndex = preload("res://world/simulation/world_entity_index.gd")

const BEHAVIORS := {
	&"herd_flee": preload("res://world/simulation/behaviors/herd_flee.gd"),
	&"pack_hunter": preload("res://world/simulation/behaviors/pack_hunter.gd"),
	&"thief": preload("res://world/simulation/behaviors/thief.gd"),
	&"leech": preload("res://world/simulation/behaviors/leech.gd"),
	&"scavenger": preload("res://world/simulation/behaviors/scavenger.gd"),
	&"grave_rise": preload("res://world/simulation/behaviors/grave_rise.gd"),
	&"fire_defender": preload("res://world/simulation/behaviors/fire_defender.gd"),
	&"nest_guard": preload("res://world/simulation/behaviors/nest_guard.gd"),
	&"pair_striker": preload("res://world/simulation/behaviors/pair_striker.gd"),
	&"dormant_golem": preload("res://world/simulation/behaviors/dormant_golem.gd"),
	&"hibernator": preload("res://world/simulation/behaviors/hibernator.gd"),
	&"patrol": preload("res://world/simulation/behaviors/patrol.gd"),
	&"night_guardian": preload("res://world/simulation/behaviors/night_guardian.gd"),
	&"boss_mechanic": preload("res://world/simulation/behaviors/boss_mechanic.gd"),
	&"heart_demon": preload("res://world/simulation/behaviors/heart_demon.gd"),
}


static func apply_effect(world, creature: Dictionary, effect: String, duration: float) -> void:
	if creature.is_empty() or duration <= 0.0:
		return
	if not creature.has("effects") or not creature.effects is Dictionary:
		creature["effects"] = {}
	creature.effects[effect] = maxf(float(creature.effects.get(effect, 0.0)), duration)
	world.touch(int(creature.uid))


static func notify_noise(world, pos: Array, radius: float) -> void:
	for c in world.index.entities_near(pos, radius, "creatures"):
		if float(c.get("health", 0.0)) > 0.0:
			c["noise_alert"] = 10.0


static func on_creature_hurt(world, creature: Dictionary, attacker: Dictionary) -> void:
	var definition = Rules.creature(str(creature.get("kind", "")))
	if definition == null:
		return
	var script = BEHAVIORS.get(definition.behavior)
	if script != null and script.has_method("on_hurt"):
		script.on_hurt(world, creature, attacker, definition)
	else:
		creature.state = "chase"
	creature["behavior_state"] = creature.state


## Whether a species is awake in this phase of the day (CreatureDef.active_period).
static func is_active(definition, phase: String) -> bool:
	match int(definition.active_period):
		CreatureDef.ActivePeriod.DAY:
			return phase == "day"
		CreatureDef.ActivePeriod.DUSK:
			return phase == "dusk"
		CreatureDef.ActivePeriod.NIGHT:
			return phase == "night"
		CreatureDef.ActivePeriod.DUSK_AND_NIGHT:
			return phase != "day"
	return true


## Outside its active period a creature walks home and rests there (params.rest_state, e.g. a
## rabbit's burrow); being hurt (provoked) wakes it.
static func _rest(world, creature: Dictionary, definition, ctx: Dictionary) -> void:
	if world.distance(creature.position, creature.home) > 1.0:
		creature.state = "return"
		ctx.destination = creature.home
	else:
		creature.state = str(definition.params.get("rest_state", "sleep"))
		ctx.speed = 0.0


static func _active_chunks(world) -> Dictionary:
	var active: Dictionary = {}
	for player in world.state.players.values():
		if player.get("ghost", false):
			continue
		var c := EntityIndex.chunk_coords(player.get("position", [0.0, 0.0, 0.0]))
		for dx in range(-3, 4):
			for dz in range(-3, 4):
				active[EntityIndex.chunk_key(c.x + dx, c.y + dz)] = true
	return active


static func step(world, delta: float) -> void:
	var phase := str(world.state.clock.get("phase", "day"))
	var limit: float = world.map_half() - 1.0
	# Creatures only think near living players; with nobody around (all dead or gone) nothing moves.
	var active_chunks := _active_chunks(world)

	for creature in world.state.creatures.duplicate():
		var definition = Rules.creature(str(creature.get("kind", "")))
		if definition == null:
			continue
		creature.cooldown = maxf(0.0, float(creature.get("cooldown", 0.0)) - delta)
		var old_flash := float(creature.get("hit_flash", 0.0))
		creature.hit_flash = maxf(0.0, old_flash - delta)
		if old_flash > 0.0 and creature.hit_flash == 0.0:
			world.touch(int(creature.uid))

		if float(creature.get("health", 0.0)) <= 0.0:
			creature.respawn = float(creature.get("respawn", 0.0)) - delta
			if creature.respawn <= 0.0:
				creature.health = definition.max_health
				creature.state = "idle"
				creature["behavior_state"] = "idle"
				creature["effects"] = {}
				creature["attached_peer"] = -1
				creature["provoked"] = 0.0
				creature["noise_alert"] = 0.0
				world.move_entity(creature, creature.home.duplicate(), true)
			continue

		if not active_chunks.has(world.index.entity_chunk.get(int(creature.uid), "")):
			continue

		var speed_mult: float = world.Effects.step_creature(world, creature, delta)
		if float(creature.health) <= 0.0:
			continue

		if float(creature.get("noise_alert", 0.0)) > 0.0:
			creature["noise_alert"] = maxf(0.0, float(creature["noise_alert"]) - delta)
		if float(creature.get("provoked", 0.0)) > 0.0:
			creature["provoked"] = maxf(0.0, float(creature["provoked"]) - delta)

		if speed_mult <= 0.0:
			creature.state = "idle"
			creature["behavior_state"] = "idle"
			continue

		var nearest: Dictionary = {}
		var distance: float = definition.detect_range
		for player in world.state.players.values():
			if player.get("ghost", false) or world.Effects.has(player, "stealth"):
				continue
			var value: float = world.distance(player.position, creature.position)
			if value < distance:
				distance = value
				nearest = player

		var ctx := {
			"phase": phase,
			"season": str(world.state.clock.get("season", "autumn")),
			"nearest_player": nearest,
			"nearest_dist": distance,
			"speed_mult": speed_mult,
			"destination": creature.home,
			"speed": definition.move_speed * speed_mult,
		}
		var prev_state := str(creature.get("state", "idle"))
		if not is_active(definition, phase) and float(creature.get("provoked", 0.0)) <= 0.0:
			_rest(world, creature, definition, ctx)
		else:
			var script = BEHAVIORS.get(definition.behavior, BEHAVIORS[&"herd_flee"])
			script.tick(world, creature, definition, ctx, delta)
		if not world.index.by_uid.has(int(creature.uid)):
			continue  # the behaviour removed it (a heart demon whose owner is gone)
		creature["behavior_state"] = creature.state
		if creature.state != prev_state:
			world.touch(int(creature.uid))

		var destination: Array = ctx.destination
		if creature.state == "idle":
			var t: float = world.elapsed() * 0.12 + float(creature.uid)
			destination = [float(creature.home[0]) + sin(t) * 3.0, 0.0, float(creature.home[2]) + cos(t) * 3.0]

		var moved := false
		if creature.get("in_secret_realm", false):
			moved = _move_in_bounds(creature, destination, float(ctx.speed) * delta, 1200.0 - 15.0, 1200.0 + 15.0, 1200.0 - 15.0, 1200.0 + 15.0)
		else:
			moved = move(creature, destination, float(ctx.speed) * delta, limit)
		if moved:
			world.move_entity(creature, creature.position, false)


static func _move_in_bounds(creature: Dictionary, target: Array, amount: float, min_x: float, max_x: float, min_z: float, max_z: float) -> bool:
	if amount <= 0.0:
		return false
	var source := Vector3(float(creature.position[0]), 0.0, float(creature.position[2]))
	var destination := Vector3(float(target[0]), 0.0, float(target[2]))
	var result := source.move_toward(destination, amount)
	var nx := clampf(result.x, min_x, max_x)
	var nz := clampf(result.z, min_z, max_z)
	if absf(nx - float(creature.position[0])) < 0.0001 and absf(nz - float(creature.position[2])) < 0.0001:
		return false
	creature.position = [nx, 0.0, nz]
	return true


static func move(creature: Dictionary, target: Array, amount: float, limit: float) -> bool:
	if amount <= 0.0:
		return false
	var source := Vector3(float(creature.position[0]), 0.0, float(creature.position[2]))
	var destination := Vector3(float(target[0]), 0.0, float(target[2]))
	var result := source.move_toward(destination, amount)
	var nx := clampf(result.x, -limit, limit)
	var nz := clampf(result.z, -limit, limit)
	if absf(nx - float(creature.position[0])) < 0.0001 and absf(nz - float(creature.position[2])) < 0.0001:
		return false
	creature.position = [nx, 0.0, nz]
	return true
