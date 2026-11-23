extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var nearest: Dictionary = ctx.nearest_player
	if creature.state == "flee":
		if float(creature.cooldown) <= 0.0:
			creature.state = "idle"
		else:
			ctx.speed = definition.move_speed * 1.4 * float(ctx.speed_mult)
			if not nearest.is_empty():
				var away := Vector3(float(creature.position[0]) - float(nearest.position[0]), 0.0, float(creature.position[2]) - float(nearest.position[2]))
				if away.length_squared() < 0.001:
					away = Vector3(1.0, 0.0, 0.0)
				away = away.normalized() * 5.0
				ctx.destination = [float(creature.position[0]) + away.x, 0.0, float(creature.position[2]) + away.z]
			else:
				ctx.destination = creature.home
			return

	if not nearest.is_empty() and world.distance(creature.home, creature.position) < float(definition.params.get("leash", 18.0)):
		creature.state = "chase"
		ctx.speed = definition.move_speed * 1.8 * float(ctx.speed_mult)
		ctx.destination = nearest.position
		if ctx.nearest_dist < 1.8 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 2.5
			creature.state = "flee"
	else:
		creature.state = "idle"
		ctx.destination = creature.home
