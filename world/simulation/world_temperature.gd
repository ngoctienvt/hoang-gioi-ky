extends RefCounted

const Season = preload("res://world/simulation/world_season.gd")


static func equipment_totals(player: Dictionary) -> Dictionary:
	var ins := 0.0
	var cool := 0.0
	var wp := 0.0
	var eq: Dictionary = player.get("inventory", {}).get("equipment", {})
	for slot_name in ["body", "head", "hand"]:
		var slot = eq.get(slot_name, {})
		if not slot is Dictionary or slot.is_empty():
			continue
		var id := str(slot.get("id", ""))
		if slot_name == "hand" and id != "hand_warmer":
			continue
		if int(slot.get("durability", 1)) <= 0 and ItemDB.get_item(id) != null and ItemDB.get_item(id).max_durability > 0:
			continue
		var def := ItemDB.get_item(id)
		if def == null:
			continue
		ins += def.insulation
		cool += def.cooling
		wp = minf(1.0, wp + def.waterproof)
	return {"insulation": ins, "cooling": cool, "waterproof": wp}


static func ambient_at(world, pos: Array, biome: String) -> float:
	var season_id := str(world.state.get("clock", {}).get("season", "autumn"))
	var def := Season.get_def(season_id)
	var temp := def.base_temperature if def != null else 50.0

	if biome == "crimson_volcano":
		temp += 25.0
	elif biome == "frost_peaks":
		temp -= 25.0

	var weather_kind := str(world.state.get("weather", {}).get("kind", "clear"))
	if weather_kind == "snow":
		temp -= 8.0
	elif weather_kind == "rain":
		temp -= 4.0
	elif weather_kind == "storm":
		temp -= 6.0

	var phase := str(world.state.get("clock", {}).get("phase", "day"))
	if phase == "night":
		temp -= 6.0
	elif phase == "dusk":
		temp -= 2.0

	for s in world.index.entities_near(pos, 7.0, "structures"):
		var skind := str(s.get("kind", ""))
		var d := float(world.distance(pos, s.position))
		if skind in ["campfire", "firepit"] and float(s.get("fuel", 0.0)) > 0.0:
			temp += 30.0 * maxf(0.0, 1.0 - d / 8.0)
		elif skind == "ice_structure" and float(s.get("melt", 0.0)) > 0.0:
			temp -= 28.0 * maxf(0.0, 1.0 - d / 8.0)

	return clampf(temp, -20.0, 120.0)


static func step_player(world, player: Dictionary, stats, delta: float, modifiers: Dictionary) -> void:
	var ambient := ambient_at(world, player.position, str(player.get("biome", "")))
	player["ambient_temperature"] = ambient

	var eq: Dictionary = player.get("inventory", {}).get("equipment", {})
	var hand = eq.get("hand", {})
	var target := ambient
	if hand is Dictionary and str(hand.get("id", "")) == "hand_warmer" and int(hand.get("durability", 0)) > 0:
		target += 20.0
		player["warmer_wear"] = float(player.get("warmer_wear", 0.0)) + delta
		if float(player["warmer_wear"]) >= 1.0:
			world.wear_hand(player, int(player["warmer_wear"]))
			player["warmer_wear"] = 0.0

	if float(player.get("warm_time", 0.0)) > 0.0:
		target += 20.0
	if float(player.get("cool_time", 0.0)) > 0.0:
		target -= 22.0
	if world.Effects.has(player, "cold_resist") and target < 50.0:
		target += minf(50.0 - target, world.Effects.magnitude(player, "cold_resist", 25.0))
	if world.Effects.has(player, "heat_resist") and target > 50.0:
		target -= minf(target - 50.0, world.Effects.magnitude(player, "heat_resist", 25.0))

	var totals := equipment_totals(player)
	var rate_div := 1.0
	if target < 50.0 and float(totals.insulation) > 0.0:
		target += minf(50.0 - target, float(totals.insulation) * 0.5)
		rate_div = 1.0 + float(totals.insulation) / 40.0
	elif target > 50.0 and float(totals.cooling) > 0.0:
		target -= minf(target - 50.0, float(totals.cooling) * 0.5)
		rate_div = 1.0 + float(totals.cooling) / 40.0

	target = clampf(target, 0.0, 100.0)
	var rate := (1.8 / rate_div) * delta
	stats.temperature = clampf(move_toward(stats.temperature, target, rate), 0.0, 100.0)

	if stats.temperature < 15.0 and not world.Skills.has_imprint_effect(player, "frost_immunity"):
		modifiers["health"] = float(modifiers.get("health", 0.0)) - 2.0 * delta
	elif stats.temperature > 85.0 and not world.Skills.has_imprint_effect(player, "fire_immunity"):
		modifiers["health"] = float(modifiers.get("health", 0.0)) - 2.0 * delta
