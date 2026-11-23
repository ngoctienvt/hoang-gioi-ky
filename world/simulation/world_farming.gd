extends RefCounted


static func plant(world, player: Dictionary, args: Dictionary, target: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	var id: String = inv.slots[index].id
	if id in ["pinecone", "berry_bush", "grass", "twig_bush"]:
		var pos = args.get("position", [])
		if not world.valid_position(pos) or not world.near(player, {"position": pos}, 4):
			return false
		for node in world.index.entities_near(pos, 1.5):
			var col: String = world.index.collection_of.get(int(node.uid), "")
			if col in ["nodes", "structures"]:
				return false
		var node: Dictionary = world.entity("tree" if id == "pinecone" else id, pos)
		node.merge({"stage": 0, "hits": 0, "regrow": 0.0, "age": 0.0, "sapling": id == "pinecone"})
		world.add_entity("nodes", node)
		if id == "pinecone" and world.get("Karma") != null:
			world.Karma.add_fate(world, "plant_spirit_tree")
	elif id in ["seed", "herb", "spirit_rice_seed"] and not target.is_empty() and target.kind == "farm" and world.near(player, target, 3) and target.crop == "":
		target.crop = "spirit_rice" if id == "spirit_rice_seed" else "herb"
		target.growth = 0.0
		target.watered = false
		target.water_type = ""
		world.touch(int(target.uid))
	else:
		return false
	inv.remove_item(id, 1)
	player.inventory = inv.to_dict()
	return true


static func water_farm(world, player: Dictionary, target: Dictionary, mode: String) -> bool:
	var inv = world.inventory(player)
	if mode == "harvest":
		if float(target.get("growth", 0.0)) < world.day_length() or str(target.get("crop", "")) == "":
			return false
		var result := _harvest_result(world, target)
		var extra := {"freshness": 1.0, "freshness_mult": 2.0} if str(target.get("water_type", "")) == "huyen_bang" else {}
		if inv.add_item(result, 2, extra) != 0:
			return false
		target.crop = ""
		target.growth = 0.0
		target.fertilized = false
		target.watered = false
		target.water_type = ""
		player.inventory = inv.to_dict()
		world.touch(int(target.uid))
		return true
	if str(target.get("crop", "")) == "" or mode not in ["water", "fertilize"]:
		return false
	if target.get("fertilized" if mode == "fertilize" else "watered", false):
		return false
	if mode == "fertilize":
		if not inv.remove_item("waste_pill", 1) and not inv.remove_item("spoiled_food", 1):
			return false
		target.fertilized = true
		target.growth = float(target.get("growth", 0.0)) + world.day_length() * 0.3
	else:
		var found_id := _find_water_item(inv)
		if found_id.is_empty():
			return false
		var used_wtype: String = world.Spring.water_type_from_item(found_id)
		if used_wtype == "xich_viem":
			return false
		if not inv.remove_item(found_id, 1):
			return false
		world.Access.return_bottle(world, inv, player.position)
		apply_water_to_farm(world, target, used_wtype)
	player.inventory = inv.to_dict()
	world.touch(int(target.uid))
	return true


static func apply_water_to_farm(world, target: Dictionary, wtype: String) -> void:
	if wtype == "xich_viem":
		return
	if wtype == "loi_tri":
		if world.rng.randf() < 0.30:
			target.crop = ""
			target.growth = 0.0
			target.watered = false
			target.water_type = ""
		else:
			target.watered = true
			target.water_type = wtype
			target.growth = world.day_length()
	else:
		target.watered = true
		target.water_type = wtype
		var boost := 0.45 if wtype == "thanh_moc" else 0.3
		target.growth = float(target.get("growth", 0.0)) + world.day_length() * boost


static func _harvest_result(world, target: Dictionary) -> String:
	var crop := str(target.get("crop", "herb"))
	var wtype := str(target.get("water_type", ""))
	if not target.get("watered", false) or wtype.is_empty():
		return "spirit_rice" if crop == "spirit_rice" else "herb"
	match wtype:
		"huyen_bang":
			return "frost_rice" if crop == "spirit_rice" else "snow_lotus"
		"thanh_moc":
			if world.rng.randf() < 0.5:
				return "mutant_fruit"
			return "spirit_rice" if crop == "spirit_rice" else "herb"
		"u_minh":
			return "soul_herb"
		"loi_tri":
			return "thunder_herb"
		"co_van":
			var pool := ["frost_rice", "mutant_fruit", "soul_herb", "fire_lotus", "snow_lotus"]
			return pool[world.rng.randi_range(0, pool.size() - 1)]
	return "spirit_rice" if crop == "spirit_rice" else "herb"


static func _find_water_item(inv) -> String:
	if inv.count_item("spirit_water") > 0:
		return "spirit_water"
	for wt in ["thanh_moc", "u_minh", "huyen_bang", "loi_tri", "co_van", "xich_viem"]:
		if inv.count_item("spirit_water_" + wt) > 0:
			return "spirit_water_" + wt
	return ""
