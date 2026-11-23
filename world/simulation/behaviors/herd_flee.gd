extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var params: Dictionary = definition.params
	var threat_pos: Array = []
	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty():
		threat_pos = nearest.position
	else:
		var predators: Array = params.get("predators", [])
		if not predators.is_empty():
			for c in world.index.entities_near(creature.position, definition.detect_range, "creatures"):
				if float(c.get("health", 0.0)) > 0.0 and str(c.get("kind", "")) in predators:
					threat_pos = c.position
					break

	if not threat_pos.is_empty():
		creature.state = "flee"
		var flee_speed := float(params.get("flee_speed", 4.0)) * float(ctx.speed_mult)
		ctx.speed = flee_speed
		var away := Vector3(float(creature.position[0]) - float(threat_pos[0]), 0.0, float(creature.position[2]) - float(threat_pos[2]))
		if away.length_squared() < 0.001:
			away = Vector3(1.0, 0.0, 0.0)
		away = away.normalized() * 6.0
		ctx.destination = [float(creature.position[0]) + away.x, 0.0, float(creature.position[2]) + away.z]
	else:
		creature.state = "idle"
		ctx.destination = creature.home
