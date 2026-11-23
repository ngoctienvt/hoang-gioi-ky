extends RefCounted

const Rules = preload("res://world/simulation/world_rules.gd")


static func tick(world, creature: Dictionary, definition, ctx: Dictionary, delta: float) -> void:
	var kind := str(creature.get("kind", ""))
	for tkey in ["grounded_timer", "cracked_timer", "melted_timer", "shield_broken_timer", "channel_timer", "special_cd"]:
		if float(creature.get(tkey, 0.0)) > 0.0:
			creature[tkey] = maxf(0.0, float(creature.get(tkey, 0.0)) - delta)

	if kind == "boss_ghost_general" and float(creature.get("special_cd", 0.0)) <= 0.0:
		creature["shrouded"] = true
		creature["special_cd"] = 10.0
	elif kind == "boss_iron_turtle" and float(creature.get("cracked_timer", 0.0)) <= 0.0:
		for s in world.index.entities_near(creature.position, 2.5, "structures"):
			if str(s.get("kind", "")) == "lightning_rod":
				creature["cracked_timer"] = 12.0
				break
		if float(creature.get("cracked_timer", 0.0)) <= 0.0:
			for n in world.index.entities_near(creature.position, 2.5, "nodes"):
				if str(n.get("kind", "")) in ["rock", "basalt_rock", "quartz_rock", "carved_pillar"]:
					creature["cracked_timer"] = 12.0
					break
	elif kind == "boss_thunder_roc" and float(creature.get("grounded_timer", 0.0)) <= 0.0 and float(creature.get("special_cd", 0.0)) <= 0.0:
		creature["special_cd"] = 7.0
		var near_rod := false
		for s in world.index.entities_near(creature.position, 10.0, "structures"):
			if str(s.get("kind", "")) == "lightning_rod":
				near_rod = true
				break
		if near_rod:
			creature["rod_absorbed"] = int(creature.get("rod_absorbed", 0)) + 1
			if int(creature["rod_absorbed"]) >= 2:
				creature["grounded_timer"] = 8.0
				creature["rod_absorbed"] = 0
		else:
			world.Weather.schedule_lightning(world, creature.position)
	elif kind == "boss_flame_wolf" and float(creature.get("special_cd", 0.0)) <= 0.0:
		creature["special_cd"] = 9.0
		creature["channel_timer"] = 3.0
		for pl in world.state.players.values():
			if not pl.get("ghost", false) and world.distance(pl.position, creature.position) <= 6.0:
				var dmg := 18.0
				if world.Structures.has_water_array_near(world, pl.position, 8.0):
					dmg *= 0.4
				world.hurt(pl, dmg)
	elif kind == "boss_frost_wyrm" and float(creature.get("special_cd", 0.0)) <= 0.0:
		creature["special_cd"] = 8.0
		for pl in world.state.players.values():
			if not pl.get("ghost", false) and world.distance(pl.position, creature.position) <= 6.0:
				if not world.Skills.has_imprint_effect(pl, "frost_immunity"):
					pl.stats["temperature"] = maxf(0.0, float(pl.stats.get("temperature", 50.0)) - 12.0)
				world.hurt(pl, 14.0)

	var nearest: Dictionary = ctx.get("nearest_player", {})
	if nearest.is_empty():
		creature.state = "idle"
		ctx["destination"] = creature.home
		return
	creature.state = "chase"
	ctx["destination"] = nearest.position
	if float(ctx.get("nearest_dist", 99.0)) <= 2.4 and float(creature.get("cooldown", 0.0)) <= 0.0:
		world.hurt(nearest, float(definition.damage))
		creature.cooldown = 1.6


static func on_hurt(world, creature: Dictionary, _attacker: Dictionary, _definition) -> void:
	creature.state = "chase"
	world.touch(int(creature.uid))
