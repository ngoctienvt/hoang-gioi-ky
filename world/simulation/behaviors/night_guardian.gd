extends RefCounted


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, delta: float) -> void:
	# Only the Soul Lantern (Đèn Dẫn Hồn) drives a guardian back; ordinary fires do not.
	var fear_r := float(definition.params.get("fear_radius", 6.0))
	for s in world.index.entities_near(creature.position, fear_r, "structures"):
		if str(s.get("kind", "")) == "soul_lantern":
			creature.state = "flee"
			var away := Vector3(float(creature.position[0]) - float(s.position[0]), 0.0, float(creature.position[2]) - float(s.position[2]))
			if away.length_squared() < 0.001:
				away = Vector3(1.0, 0.0, 0.0)
			away = away.normalized() * 7.0
			ctx.destination = [float(creature.position[0]) + away.x, 0.0, float(creature.position[2]) + away.z]
			return

	var nearest: Dictionary = ctx.nearest_player
	if not nearest.is_empty():
		creature.state = "chase"
		ctx.destination = nearest.position
		if nearest.has("stats"):
			nearest.stats.dao = maxf(0.0, float(nearest.stats.get("dao", 100.0)) - delta * 0.6)
		if ctx.nearest_dist < 1.8 and float(creature.cooldown) <= 0.0:
			world.hurt(nearest, definition.damage)
			creature.cooldown = 1.6
	else:
		creature.state = "wander"
		ctx.destination = creature.home
