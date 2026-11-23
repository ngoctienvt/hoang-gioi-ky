extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty():
		creature.state = "flee"
		ctx.speed = float(definition.params.get("flee_speed", 4.8)) * float(ctx.speed_mult)
		var away := Vector3(float(creature.position[0]) - float(nearest.position[0]), 0.0, float(creature.position[2]) - float(nearest.position[2]))
		if away.length_squared() < 0.001:
			away = Vector3(1.0, 0.0, 0.0)
		away = away.normalized() * 6.0
		ctx.destination = [float(creature.position[0]) + away.x, 0.0, float(creature.position[2]) + away.z]
		return

	var search_r := float(definition.params.get("search_radius", 12.0))
	for drop in world.index.entities_near(creature.position, search_r, "drops"):
		var item := ItemDB.get_item(str(drop.get("id", "")))
		if item != null and item.get_tag(&"meat") > 0.0:
			creature.state = "special"
			ctx.destination = drop.position
			if world.distance(creature.position, drop.position) < 1.1:
				world.remove_entity(drop)
				world.touch(int(creature.uid))
			return

	creature.state = "idle"
	ctx.destination = creature.home
