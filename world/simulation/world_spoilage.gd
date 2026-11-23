extends RefCounted

const Temperature = preload("res://world/simulation/world_temperature.gd")
const Structures = preload("res://world/simulation/world_structures.gd")


static func step(world, delta: float) -> void:
	var season := str(world.state.get("clock", {}).get("season", "autumn"))
	var weather := str(world.state.get("weather", {}).get("kind", "clear"))

	for player in world.state.players.values() + world.state.offline_players.values():
		var ambient := float(player.get("ambient_temperature", 50.0))
		var mult := 0.75 if ambient < 20.0 else 1.0
		_tick_slots(player.inventory.slots, delta, mult, false, season, weather)

	# Every storage structure: food spoils at the normal rate (the ice cellar halves it) and paper
	# soaks in spring unless the container is moisture-proof (talisman chest).
	for s in world.state.structures:
		if str(s.get("kind", "")) not in Structures.CHEST_KINDS:
			continue
		var ambient := Temperature.ambient_at(world, s.position, str(s.get("biome", world.biome_at(s.position))))
		var mult := 0.5 if str(s.get("kind", "")) == "ice_cellar" else 1.0
		if ambient < 20.0:
			mult *= 0.75
		if _tick_slots(s.slots, delta, mult, bool(s.get("moisture_proof", false)), season, weather):
			world.touch(int(s.uid))

	for drop in world.state.drops.duplicate():
		var id := str(drop.get("id", ""))
		var item := ItemDB.get_item(id)
		if item == null:
			continue
		var soaks := season == "spring" and item.get_tag(&"paper") > 0.0
		if item.spoil_time <= 0.0 and not soaks:
			continue
		var extra: Dictionary = drop.get("extra", {})
		var changed := false
		if item.spoil_time > 0.0:
			var ambient := Temperature.ambient_at(world, drop.position, world.biome_at(drop.position))
			var mult := 0.75 if ambient < 20.0 else 1.0
			var f_mult := float(extra.get("freshness_mult", 1.0))
			var raw := float(extra.get("_f", extra.get("freshness", 1.0)))
			raw -= (delta * mult) / maxf(1.0, item.spoil_time * f_mult)
			if raw <= 0.0:
				drop["id"] = "spoiled_food"
				extra.erase("freshness")
				extra.erase("_f")
				extra.erase("freshness_mult")
				changed = true
			else:
				extra["_f"] = raw
				var q := snappedf(raw, 0.05)
				if absf(q - float(extra.get("freshness", 1.0))) >= 0.049:
					extra["freshness"] = q
					changed = true
		if soaks:
			var soak_rate := (1.0 / 240.0) * (2.0 if weather in ["rain", "storm"] else 1.0)
			var soak := float(extra.get("soak", 0.0)) + delta * soak_rate
			if soak >= 1.0:
				world.remove_entity(drop)
				continue
			extra["soak"] = soak
		if changed:
			world.touch(int(drop.uid))


static func _tick_slots(slots: Array, delta: float, rate_mult: float, moisture_proof: bool, season: String, weather: String) -> bool:
	var changed := false
	for i in slots.size():
		var slot: Dictionary = slots[i]
		if slot.is_empty():
			continue
		var item := ItemDB.get_item(str(slot.get("id", "")))
		if item == null:
			continue
		if item.spoil_time > 0.0:
			var f_mult := float(slot.get("freshness_mult", 1.0))
			var raw := float(slot.get("_f", slot.get("freshness", 1.0)))
			raw -= (delta * rate_mult) / maxf(1.0, item.spoil_time * f_mult)
			if raw <= 0.0:
				slot["id"] = "spoiled_food"
				slot.erase("freshness")
				slot.erase("_f")
				slot.erase("freshness_mult")
				changed = true
			else:
				slot["_f"] = raw
				var q := snappedf(raw, 0.05)
				if absf(q - float(slot.get("freshness", 1.0))) >= 0.049:
					slot["freshness"] = q
					changed = true
		if season == "spring" and not moisture_proof and item.get_tag(&"paper") > 0.0:
			var soak_rate := (1.0 / 240.0) * (2.0 if weather in ["rain", "storm"] else 1.0)
			var soak := float(slot.get("soak", 0.0)) + delta * soak_rate
			if soak >= 1.0:
				slots[i] = {}
				changed = true
			else:
				slot["soak"] = soak
	return changed
