extends RefCounted


static func ensure_effects(entity: Dictionary) -> Dictionary:
	if not entity.has("effects") or not entity.effects is Dictionary:
		entity["effects"] = {}
	return entity.effects


static func apply(world, entity: Dictionary, effect_name: String, magnitude: float, duration: float) -> void:
	if entity.is_empty():
		return
	if effect_name == "banish_heart_demon":
		var peer_id := -int(entity.get("uid", 0))
		if peer_id > 0:
			world.HeartDemon.banish_for_player(world, peer_id)
		return
	if effect_name == "detox":
		if entity.has("stats") and entity.stats is Dictionary:
			var p := maxf(0.0, float(entity.stats.get("poison", 0.0)) - magnitude)
			entity.stats.poison = p
			entity.poison = p
			if p <= float(entity.get("poison_threshold", 50.0)) and entity.has("effects") and entity.effects is Dictionary:
				entity.effects.erase("nausea")
		return
	var fx := ensure_effects(entity)
	fx[effect_name] = {"mag": magnitude, "time": duration}
	if effect_name == "night_vision":
		entity["night_vision"] = maxf(float(entity.get("night_vision", 0.0)), duration)
	elif effect_name == "speed_boost":
		entity["speed_boost_time"] = maxf(float(entity.get("speed_boost_time", 0.0)), duration)
	elif effect_name == "spirit_sight":
		entity["sense_time"] = maxf(float(entity.get("sense_time", 0.0)), duration)
	var uid := int(entity.get("uid", 0))
	if uid > 0:
		world.touch(uid)


static func apply_item(world, player: Dictionary, item_def) -> void:
	if item_def == null:
		return
	var item_effects = item_def.get("effects")
	if not item_effects is Dictionary:
		return
	for effect_name in item_effects:
		var spec = item_effects[effect_name]
		if spec is Array and spec.size() >= 2:
			apply(world, player, str(effect_name), float(spec[0]), float(spec[1]))


static func has(entity: Dictionary, effect_name: String) -> bool:
	var fx = entity.get("effects", {})
	if not fx is Dictionary or not fx.has(effect_name):
		return false
	var entry = fx[effect_name]
	if entry is float or entry is int:
		return float(entry) > 0.0
	return entry is Dictionary and float(entry.get("time", 0.0)) > 0.0


static func magnitude(entity: Dictionary, effect_name: String, default_val: float = 0.0) -> float:
	if not has(entity, effect_name):
		return default_val
	var entry = entity.effects[effect_name]
	if entry is Dictionary:
		return float(entry.get("mag", default_val))
	return default_val


static func step_player(world, player: Dictionary, delta: float) -> void:
	var fx := ensure_effects(player)
	for key in fx.keys():
		var entry = fx[key]
		if not entry is Dictionary:
			fx.erase(key)
			continue
		entry.time = float(entry.get("time", 0.0)) - delta
		if entry.time <= 0.0:
			fx.erase(key)
	if has(player, "temp_lock") and player.has("stats") and player.stats is Dictionary:
		player.stats.temperature = magnitude(player, "temp_lock", 50.0)
	if has(player, "nausea") and player.has("stats") and player.stats is Dictionary:
		player.stats.dao = maxf(0.0, float(player.stats.get("dao", 100.0)) - 0.8 * delta)


static func step_creature(world, creature: Dictionary, delta: float) -> float:
	var fx := ensure_effects(creature)
	var touched := false
	for key in fx.keys():
		var entry = fx[key]
		if entry is float or entry is int:
			var rem := float(entry) - delta
			if rem <= 0.0:
				fx.erase(key)
				touched = true
			else:
				fx[key] = rem
		elif entry is Dictionary:
			entry.time = float(entry.get("time", 0.0)) - delta
			if entry.time <= 0.0:
				fx.erase(key)
				touched = true
		else:
			fx.erase(key)
			touched = true
	if has(creature, "burn") and float(creature.get("health", 0.0)) > 0.0:
		var dps := magnitude(creature, "burn", 4.0)
		creature.health = float(creature.health) - dps * delta
		touched = true
		if float(creature.health) <= 0.0:
			world.Combat.kill(world, creature)
			return 0.0
	if touched and int(creature.get("uid", 0)) > 0:
		world.touch(int(creature.uid))
	if has(creature, "stun"):
		return 0.0
	if has(creature, "slow"):
		return clampf(1.0 - magnitude(creature, "slow", 0.4), 0.1, 1.0)
	return 1.0
