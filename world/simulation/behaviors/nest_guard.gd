extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	var nest_radius := float(definition.params.get("nest_radius", 6.0))
	var leash := float(definition.params.get("leash", 14.0))
	var target: Dictionary = {}
	var best_d := nest_radius
	for p in world.state.players.values():
		if p.get("ghost", false):
			continue
		var d_nest := float(world.distance(creature.home, p.position))
		if d_nest <= nest_radius or (creature.state == "chase" and d_nest <= leash):
			if d_nest < best_d or target.is_empty():
				best_d = d_nest
				target = p

	if not target.is_empty():
		creature.state = "chase"
		ctx.destination = target.position
		if world.distance(creature.position, target.position) < 1.8 and float(creature.cooldown) <= 0.0:
			world.hurt(target, definition.damage)
			creature.cooldown = 1.6
	else:
		creature.state = "idle"
		ctx.destination = creature.home
