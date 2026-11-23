extends RefCounted

const Season = preload("res://world/simulation/world_season.gd")
const Temperature = preload("res://world/simulation/world_temperature.gd")
const WOODEN_STRUCTURES := ["chest", "workbench", "farm"]


static func player_weather(world, player: Dictionary) -> String:
	var w := str(world.state.get("weather", {}).get("kind", "clear"))
	var biome := str(player.get("biome", ""))
	if biome == "frost_peaks" and w == "rain":
		return "snow"
	if biome == "crimson_volcano" and w == "snow":
		return "clear"
	return w


static func schedule_lightning(world, pos: Array) -> void:
	var weather: Dictionary = world.state.get("weather", {})
	if not weather.has("warnings") or not weather.warnings is Array:
		weather["warnings"] = []
	weather.warnings.append({
		"id": world.next_uid,
		"position": [float(pos[0]), 0.0, float(pos[2])],
		"timer": 2.0,
	})
	world.next_uid += 1


static func strike_at(world, pos: Array) -> Dictionary:
	var best_rod: Dictionary = {}
	var best_dist := 10.0001
	for s in world.index.entities_near(pos, 10.0, "structures"):
		if str(s.get("kind", "")) == "lightning_rod":
			var d := float(world.distance(pos, s.position))
			if d < best_dist:
				best_dist = d
				best_rod = s
	if not best_rod.is_empty():
		best_rod["charges"] = int(best_rod.get("charges", 0)) + 1
		world.touch(int(best_rod.uid))
		world.log_event("lightning_rod_charged", {"uid": best_rod.uid})
		return {"absorbed": true, "rod_uid": best_rod.uid}

	for player in world.state.players.values():
		if not player.get("ghost", false) and world.distance(pos, player.position) <= 2.5:
			if world.Skills.has_imprint_effect(player, "lightning_surge"):
				world.Effects.apply(world, player, "speed_boost", 0.4, 8.0)
			else:
				world.hurt(player, 30.0)
	for s in world.index.entities_near(pos, 3.0, "structures"):
		if str(s.get("kind", "")) in WOODEN_STRUCTURES:
			s["burning"] = 12.0
			world.touch(int(s.uid))
	world.Creatures.notify_noise(world, pos, 12.0)
	world.log_event("lightning_strike", {"position": pos.duplicate()})
	return {"absorbed": false}


static func step(world, delta: float) -> void:
	if not world.state.has("weather") or not world.state.weather is Dictionary:
		world.state["weather"] = {"kind": "clear", "timer": 0.0, "lightning_cd": 0.0, "fire_cd": 0.0, "warnings": []}
	var weather: Dictionary = world.state.weather
	var season_id := str(world.state.get("clock", {}).get("season", "autumn"))

	# 1. Roll weather every half day
	weather["timer"] = float(weather.get("timer", 0.0)) + delta
	if float(weather["timer"]) >= world.day_length() * 0.5:
		weather["timer"] = 0.0
		var def := Season.get_def(season_id)
		var roll: float = world.rng.randf()
		var sc := def.storm_chance if def != null else 0.05
		var snc := def.snow_chance if def != null else 0.0
		var rc := def.rain_chance if def != null else 0.2
		if roll < sc:
			weather["kind"] = "storm"
		elif roll < sc + snc:
			weather["kind"] = "snow"
		elif roll < sc + snc + rc:
			weather["kind"] = "rain"
		else:
			weather["kind"] = "clear"

	# 2. Tick existing lightning warnings
	var warnings: Array = weather.get("warnings", [])
	var next_warnings: Array = []
	for w in warnings:
		if not w is Dictionary:
			continue
		w["timer"] = float(w.get("timer", 0.0)) - delta
		if float(w["timer"]) <= 0.0:
			strike_at(world, w.get("position", [0.0, 0.0, 0.0]))
		else:
			next_warnings.append(w)
	weather["warnings"] = next_warnings

	# 3. Schedule periodic lightning in thunder_gorge or during storm
	weather["lightning_cd"] = maxf(0.0, float(weather.get("lightning_cd", 0.0)) - delta)
	if float(weather["lightning_cd"]) <= 0.0:
		weather["lightning_cd"] = 15.0
		var candidates: Array = []
		for p in world.state.players.values():
			if not p.get("ghost", false) and (str(p.get("biome", "")) == "thunder_gorge" or str(weather.get("kind", "")) == "storm"):
				candidates.append(p)
		if not candidates.is_empty():
			var target_p: Dictionary = candidates[world.rng.randi_range(0, candidates.size() - 1)]
			var offset := [world.rng.randf_range(-5.0, 5.0), 0.0, world.rng.randf_range(-5.0, 5.0)]
			var lpos := [
				clampf(float(target_p.position[0]) + offset[0], -world.map_half() + 1.0, world.map_half() - 1.0),
				0.0,
				clampf(float(target_p.position[2]) + offset[2], -world.map_half() + 1.0, world.map_half() - 1.0),
			]
			schedule_lightning(world, lpos)

	# 4. Summer spontaneous combustion & burning tick
	weather["fire_cd"] = maxf(0.0, float(weather.get("fire_cd", 0.0)) - delta)
	if season_id == "summer" and str(weather.get("kind", "")) == "clear" and float(weather["fire_cd"]) <= 0.0:
		weather["fire_cd"] = 10.0
		for p in world.state.players.values():
			if p.get("ghost", false):
				continue
			for s in world.index.entities_near(p.position, 12.0, "structures"):
				if str(s.get("kind", "")) in WOODEN_STRUCTURES and float(s.get("burning", 0.0)) <= 0.0:
					if Temperature.ambient_at(world, s.position, world.biome_at(s.position)) > 80.0 and not _has_ice_near(world, s.position):
						if world.rng.randf() < 0.05:
							s["burning"] = 12.0
							world.touch(int(s.uid))

	var is_wet := str(weather.get("kind", "")) in ["rain", "storm"]
	for s in world.state.structures.duplicate():
		var burn := float(s.get("burning", 0.0))
		if burn <= 0.0:
			continue
		if is_wet:
			s["burning"] = 0.0
			world.touch(int(s.uid))
			continue
		s["burning"] = maxf(0.0, burn - delta)
		s["health"] = float(s.get("health", 200.0)) - 5.0 * delta
		if float(s["health"]) <= 0.0:
			world.remove_entity(s)
		else:
			world.touch(int(s.uid))
			for adj in world.index.entities_near(s.position, 3.0, "structures"):
				if adj != s and str(adj.get("kind", "")) in WOODEN_STRUCTURES and float(adj.get("burning", 0.0)) <= 0.0:
					adj["burning"] = 10.0
					world.touch(int(adj.uid))

	# 5. Winter frozen springs
	for node in world.state.nodes:
		if str(node.get("kind", "")) != "spring":
			continue
		if season_id == "winter" and str(node.get("water_type", "thanh_moc")) != "xich_viem":
			var thaw := float(node.get("ice_thaw_timer", 0.0))
			if thaw > 0.0:
				node["ice_thaw_timer"] = maxf(0.0, thaw - delta)
				if node["ice_thaw_timer"] <= 0.0:
					node["frozen"] = true
					node["ice_hits"] = 0
					world.touch(int(node.uid))
			elif not node.get("frozen", false):
				node["frozen"] = true
				node["ice_hits"] = 0
				world.touch(int(node.uid))
		elif node.get("frozen", false):
			node["frozen"] = false
			node["ice_hits"] = 0
			world.touch(int(node.uid))


static func _has_ice_near(world, pos: Array) -> bool:
	for s in world.index.entities_near(pos, 10.0, "structures"):
		if str(s.get("kind", "")) == "ice_structure" and float(s.get("melt", 0.0)) > 0.0:
			return true
	return false


static func apply_player_weather(world, player: Dictionary, delta: float, modifiers: Dictionary) -> void:
	var w := player_weather(world, player)
	if w not in ["rain", "storm"]:
		return
	var equip := Temperature.equipment_totals(player)
	var base_drain := 0.35 if w == "rain" else 0.55
	var drain := base_drain * (1.0 - clampf(float(equip.waterproof), 0.0, 1.0))
	if str(player.get("character", "beast_bloodline")) == "beast_bloodline":
		drain *= 1.25
	modifiers["dao"] = float(modifiers.get("dao", 0.0)) - drain * delta
