extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	# Hibernates through winter unless woken by a blow or a loud noise; awake the rest of the year.
	var awake: bool = ctx.season != "winter" or float(creature.get("provoked", 0.0)) > 0.0 or float(creature.get("noise_alert", 0.0)) > 0.0
	if not awake:
		creature.state = "sleep"
		ctx.speed = 0.0
		return

	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty() and world.distance(creature.home, creature.position) < float(definition.params.get("leash", 18.0)):
		creature.state = "chase"
		ctx.destination = nearest.position
		if ctx.nearest_dist < 1.9 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 1.8
	else:
		creature["provoked"] = 0.0
		creature["noise_alert"] = 0.0
		if world.distance(creature.position, creature.home) > 1.5:
			creature.state = "return"
			ctx.destination = creature.home
		else:
			creature.state = "idle" if ctx.season != "winter" else "sleep"
			if creature.state == "sleep":
				ctx.speed = 0.0


static func on_hurt(_world, creature: Dictionary, _attacker: Dictionary, _definition: CreatureDef) -> void:
	creature["provoked"] = 15.0
	creature.state = "chase"
