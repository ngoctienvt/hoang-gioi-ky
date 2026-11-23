extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var nearest: Dictionary = ctx.nearest_player
	var leash := float(definition.params.get("leash", 16.0))
	if not nearest.is_empty() and world.distance(creature.home, creature.position) < leash:
		creature.state = "chase"
		ctx.destination = nearest.position
		if ctx.nearest_dist < 1.8 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 1.6
		return

	var r := float(definition.params.get("patrol_radius", 6.0))
	var hx := float(creature.home[0])
	var hz := float(creature.home[2])
	var waypoints := [
		[hx + r, 0.0, hz],
		[hx, 0.0, hz + r],
		[hx - r, 0.0, hz],
		[hx, 0.0, hz - r],
	]
	var idx: int = int(creature.get("patrol_idx", 0)) % 4
	var wp: Array = waypoints[idx]
	if world.distance(creature.position, wp) < 0.8:
		idx = (idx + 1) % 4
		creature["patrol_idx"] = idx
		wp = waypoints[idx]
	creature.state = "wander"
	ctx.destination = wp
