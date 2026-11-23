extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var provoked := float(creature.get("provoked", 0.0))
	if provoked <= 0.0:
		creature.state = "idle"
		ctx.destination = creature.home
		return

	var nearest: Dictionary = ctx.nearest_player
	if nearest.is_empty():
		creature.state = "return"
		ctx.destination = creature.home
		return

	creature.state = "chase"
	ctx.destination = nearest.position
	if ctx.nearest_dist <= 4.0 and float(creature.cooldown) <= 0.0:
		creature.state = "special"
		for p in world.state.players.values():
			if not p.get("ghost", false) and world.distance(creature.position, p.position) <= 4.0:
				world.hurt(p, definition.damage)
				# Fire breath leaves the victim burning for a few seconds.
				world.Effects.apply(world, p, "burn", float(definition.params.get("burn_dps", 3.0)), float(definition.params.get("burn_time", 4.0)))
		creature.cooldown = 2.5


static func on_hurt(_world, creature: Dictionary, _attacker: Dictionary, _definition: CreatureDef) -> void:
	creature["provoked"] = 12.0
	creature.state = "chase"
