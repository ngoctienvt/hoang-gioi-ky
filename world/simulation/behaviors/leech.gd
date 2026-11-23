extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, delta: float) -> void:
	var attached_peer: int = int(creature.get("attached_peer", -1))
	if attached_peer > 0:
		var victim: Dictionary = world.state.players.get(str(attached_peer), {})
		if victim.is_empty() or victim.get("ghost", false) or world.distance(creature.position, victim.position) > 4.0:
			creature["attached_peer"] = -1
			creature.state = "idle"
			return
		creature.state = "special"
		ctx.destination = victim.position
		ctx.speed = 12.0
		var drain := maxf(2.0, definition.damage) * delta
		world.hurt(victim, drain)
		return

	if creature.state == "flee":
		ctx.destination = creature.home
		if world.distance(creature.position, creature.home) < 1.2 or float(creature.cooldown) <= 0.0:
			creature.state = "idle"
		return

	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty() and world.distance(creature.home, creature.position) < 16.0:
		creature.state = "chase"
		ctx.destination = nearest.position
		if ctx.nearest_dist <= 1.2:
			creature["attached_peer"] = -int(nearest.uid)
			creature.state = "special"
	else:
		creature.state = "idle"
		ctx.destination = creature.home


static func on_hurt(_world, creature: Dictionary, _attacker: Dictionary, _definition: CreatureDef) -> void:
	creature["attached_peer"] = -1
	creature.state = "flee"
	creature.cooldown = 2.0
