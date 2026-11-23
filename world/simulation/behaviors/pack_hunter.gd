extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, delta: float) -> void:
	var params: Dictionary = definition.params
	var leash := float(params.get("leash", 18.0))
	var nearest: Dictionary = ctx.nearest_player
	var dist: float = ctx.nearest_dist

	if not nearest.is_empty() and world.distance(creature.home, creature.position) < leash:
		creature.state = "chase"
		ctx.destination = nearest.position
		var dao_drain := float(params.get("dao_drain", 0.4))
		if dao_drain > 0.0 and nearest.has("stats"):
			nearest.stats.dao = maxf(0.0, float(nearest.stats.get("dao", 100.0)) - delta * dao_drain)
		if dist < 1.7 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 1.5
		return

	# Hunt prey species if no player target
	var prey_kinds: Array = params.get("prey_kinds", [])
	if not prey_kinds.is_empty() and world.distance(creature.home, creature.position) < leash:
		for c in world.index.entities_near(creature.position, definition.detect_range, "creatures"):
			if float(c.get("health", 0.0)) > 0.0 and str(c.get("kind", "")) in prey_kinds and str(c.get("state", "")) != "burrow":
				creature.state = "chase"
				ctx.destination = c.position
				if world.distance(creature.position, c.position) < 1.5 and float(creature.cooldown) <= 0.0:
					c.health = float(c.health) - definition.damage
					c.hit_flash = 0.2
					creature.cooldown = 1.5
					if float(c.health) <= 0.0:
						world.Combat.kill(world, c, false)
					else:
						world.touch(int(c.uid))
				return

	# A packmate was attacked: run to where the attacker stood, then give up.
	var aggro: Array = creature.get("aggro_pos", [])
	if aggro.size() == 3 and world.distance(creature.home, creature.position) < leash:
		if world.distance(creature.position, aggro) > 1.5:
			creature.state = "chase"
			ctx.destination = aggro
			return
	creature.erase("aggro_pos")

	if world.distance(creature.position, creature.home) > 1.5:
		creature.state = "return"
		ctx.destination = creature.home
	else:
		creature.state = "idle"
		ctx.destination = creature.home


static func on_hurt(world, creature: Dictionary, attacker: Dictionary, definition: CreatureDef) -> void:
	creature.state = "chase"
	var pack_radius := float(definition.params.get("pack_radius", 8.0))
	if pack_radius <= 0.0:
		return
	for other in world.index.entities_near(creature.position, pack_radius, "creatures"):
		if other != creature and str(other.get("kind", "")) == str(creature.get("kind", "")) and float(other.get("health", 0.0)) > 0.0:
			other.state = "chase"
			if not attacker.is_empty():
				other["aggro_pos"] = attacker.get("position", []).duplicate()
			world.touch(int(other.uid))
