extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var params: Dictionary = definition.params
	if creature.state == "flee":
		ctx.speed = float(params.get("flee_speed", 4.0)) * float(ctx.speed_mult)
		ctx.destination = creature.home
		if world.distance(creature.position, creature.home) < 1.0:
			creature.state = "idle"
		return
	var stolen: Array = creature.get("stolen", [])
	if stolen.is_empty():
		var steal_radius := float(params.get("steal_radius", 7.0))
		for drop in world.index.entities_near(creature.position, steal_radius, "drops"):
			ctx.destination = drop.position
			creature.state = "special"
			if world.distance(creature.position, drop.position) < 1.0:
				stolen.append(drop.duplicate(true))
				creature["stolen"] = stolen
				world.remove_entity(drop)
				world.touch(int(creature.uid))
			return
		creature.state = "idle"
		ctx.destination = creature.home
	else:
		creature.state = "return"
		ctx.destination = creature.home


static func on_hurt(_world, creature: Dictionary, _attacker: Dictionary, _definition: CreatureDef) -> void:
	creature.state = "flee"
