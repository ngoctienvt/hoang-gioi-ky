extends RefCounted


static func is_spirit_water(id: String) -> bool:
	return id == "spirit_water" or id.begins_with("spirit_water_")


static func water_type_from_item(id: String) -> String:
	if id == "spirit_water":
		return "thanh_moc"
	if id.begins_with("spirit_water_"):
		return id.trim_prefix("spirit_water_")
	return ""


static func apply_water_effect(player: Dictionary, water_type: String) -> void:
	match water_type:
		"thanh_moc":
			player.spring_heal = 30.0
		"u_minh":
			player.sense_time = maxf(float(player.get("sense_time", 0.0)), 15.0)
			player.stats.dao = maxf(0.0, float(player.stats.get("dao", 100.0)) - 10.0)
		"xich_viem":
			player.warm_time = 60.0
		"loi_tri":
			player.speed_boost_time = 20.0
		"huyen_bang":
			player.cool_time = 60.0
		"co_van":
			pass


static func perform(world, player: Dictionary, verb: String, args: Dictionary) -> bool:
	if verb == "temper":
		return world.Tempering.temper(world, player, args)
	var target: Dictionary = world.find_any(args.get("uid", -1))
	if verb == "plant":
		return world.Farming.plant(world, player, args, target)
	if verb != "water" or target.is_empty() or not world.near(player, target, 3):
		return false
	var mode := str(args.get("mode", "fill" if target.kind == "spring" else "water"))
	if target.kind == "spring":
		var inv = world.inventory(player)
		var wtype := str(target.get("water_type", "thanh_moc"))
		if mode == "fill":
			if target.get("frozen", false):
				return false
			var item_id := "spirit_water_" + wtype
			if ItemDB.get_item(item_id) == null:
				item_id = "spirit_water"
			if not inv.remove_item("water_bottle", 1) or inv.add_item(item_id, 1, {"expires": world.elapsed() + world.day_length() * 3}) != 0:
				return false
			player.inventory = inv.to_dict()
			return true
		if mode in ["drink", "bathe"]:
			apply_water_effect(player, wtype)
			return true
		return false
	if target.kind == "farm":
		return world.Farming.water_farm(world, player, target, mode)
	return false


static func step(world, delta: float) -> void:
	for target in world.state.structures:
		var changed := false
		if expire_slots(target.slots, world.elapsed()):
			changed = true
		if is_spirit_water(str(target.solvent)) and float(target.get("solvent_expires", INF)) <= world.elapsed():
			target.solvent = "plain_water"
			changed = true
		if target.kind == "farm" and target.crop != "":
			var rate := 1.8 if (target.get("watered", false) and str(target.get("water_type", "")) == "thanh_moc") else (1.5 if target.get("watered", false) else 1.0)
			target.growth += delta * rate
			changed = true
		if changed:
			world.touch(int(target.uid))
	for player in world.state.players.values() + world.state.offline_players.values():
		expire_slots(player.inventory.slots, world.elapsed())
	for drop in world.state.drops:
		if is_spirit_water(str(drop.id)) and float(drop.extra.get("expires", INF)) <= world.elapsed():
			drop.id = "plain_water"
			drop.extra.erase("expires")
			world.touch(int(drop.uid))


static func expire_slots(slots: Array, time: float) -> bool:
	var changed := false
	for slot in slots:
		if is_spirit_water(str(slot.get("id", ""))) and float(slot.get("expires", INF)) <= time:
			slot.id = "plain_water"
			slot.erase("expires")
			changed = true
	return changed
