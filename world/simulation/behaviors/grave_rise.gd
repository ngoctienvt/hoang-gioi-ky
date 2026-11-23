extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	if ctx.phase == "day":
		if world.distance(creature.position, creature.home) > 1.0:
			creature.state = "return"
			ctx.destination = creature.home
		else:
			creature.state = "sleep"
			ctx.speed = 0.0
		return

	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty() and world.distance(creature.home, creature.position) < float(definition.params.get("leash", 16.0)):
		creature.state = "chase"
		ctx.destination = nearest.position
		if ctx.nearest_dist < 1.7 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 1.6
	else:
		creature.state = "wander"
		var t: float = world.elapsed() * 0.2 + float(creature.uid)
		ctx.destination = [float(creature.home[0]) + sin(t) * 4.0, 0.0, float(creature.home[2]) + cos(t) * 4.0]
