extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

static func step(world, delta: float) -> void:
	var phase = str(world.state.clock.get("phase", "day"))
	for creature in world.state.creatures:
		var definition = Rules.creature(creature.kind)
		creature.cooldown = maxf(0, creature.cooldown - delta)
		creature.hit_flash = maxf(0, creature.get("hit_flash", 0) - delta)
		if creature.health <= 0:
			creature.respawn -= delta
			if creature.respawn <= 0:
				creature.health = definition.max_health
				creature.position = creature.home.duplicate()
				creature.state = "idle"
			continue
		var nearest: Dictionary = {}
		var distance = definition.detect_range
		for player in world.state.players.values():
			var value = world.distance(player.position, creature.position)
			if not player.ghost and value < distance:
				distance = value
				nearest = player
		var destination: Array = creature.home
		var speed = definition.move_speed
		if creature.kind == "wolf":
			if phase == "day":
				creature.state = "sleep"
			elif not nearest.is_empty() and world.distance(creature.home, creature.position) < 18:
				creature.state = "chase"
				destination = nearest.position
				speed = definition.move_speed
				nearest.stats.dao = maxf(0, float(nearest.stats.get("dao", 100)) - delta * 0.4)
				if distance < 1.7 and creature.cooldown <= 0:
					world.hurt(nearest, definition.damage)
					creature.cooldown = 1.5
			else:
				creature.state = "return"
		elif creature.kind == "rabbit":
			creature.state = "burrow" if phase == "night" else "idle"
			if not nearest.is_empty():
				creature.state = "flee"
				speed = 4.0
		elif creature.kind == "monkey":
			if definition.active_period == 1 and phase != "day":
				creature.state = "return"
			elif creature.state == "flee":
				speed = 4.0
				if world.distance(creature.position, creature.home) < 1:
					creature.state = "idle"
			elif creature.stolen.is_empty():
				for drop in world.state.drops:
					if world.distance(creature.position, drop.position) < 7:
						destination = drop.position
						creature.state = "steal"
						if world.distance(creature.position, drop.position) < 1:
							creature.stolen.append(drop.duplicate(true))
							world.state.drops.erase(drop)
						break
			else:
				creature.state = "return"
		if creature.state == "idle":
			var t = world.elapsed() * 0.12 + creature.uid
			destination = [creature.home[0] + sin(t) * 3, 0.0, creature.home[2] + cos(t) * 3]
		move(creature, destination, speed * delta)

static func move(creature: Dictionary, target: Array, amount: float) -> void:
	var source = Vector3(creature.position[0], 0, creature.position[2])
	var destination = Vector3(target[0], 0, target[2])
	var result = source.move_toward(destination, amount)
	creature.position = [clampf(result.x, -39, 39), 0.0, clampf(result.z, -39, 39)]
