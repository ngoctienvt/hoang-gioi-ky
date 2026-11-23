extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")


static func step(world, delta: float) -> void:
	for uid in world.regrowing_uids.keys():
		var node: Dictionary = world.index.find(uid)
		if node.is_empty():
			world.regrowing_uids.erase(uid)
			continue
		var changed := false
		if float(node.get("regrow", 0.0)) > 0.0:
			var before := ceili(float(node.regrow))
			node.regrow = maxf(0.0, float(node.regrow) - delta)
			# Countdowns replicate on whole-second steps only (see StateReplicator.COARSE_TIMERS).
			changed = ceili(float(node.regrow)) != before
			if node.regrow == 0.0:
				changed = true
				node.stage = 0
				node.hits = 0
				node.depleted = false
		if node.get("sapling", false):
			var age_before := floori(float(node.get("age", 0.0)))
			node.age = float(node.get("age", 0.0)) + delta
			changed = changed or floori(float(node.age)) != age_before
			if node.age >= world.day_length() * 2.0:
				node.sapling = false
				node.stage = 0
				changed = true
		if changed:
			world.touch(int(uid))
		if float(node.get("regrow", 0.0)) <= 0.0 and not node.get("sapling", false):
			world.regrowing_uids.erase(uid)


static func work(world, player: Dictionary, node: Dictionary, auto_equip: bool = false) -> bool:
	if node.is_empty() or node.get("sapling", false):
		return false
	if str(node.get("kind", "")) == "spring" and node.get("frozen", false):
		if float(player.beast_time) > 0.0:
			return false
		if not world.has_tool(player, "pickaxe", 1):
			if not auto_equip or not world.Access.equip_tool(world, player, "pickaxe", 1):
				return false
		world.wear_hand(player, 1)
		node["ice_hits"] = int(node.get("ice_hits", 0)) + 1
		if int(node["ice_hits"]) >= 3:
			node["frozen"] = false
			node["ice_hits"] = 0
			node["ice_thaw_timer"] = world.day_length() * 0.5
		world.touch(int(node.uid))
		return true
	var definition = Rules.node(str(node.kind))
	if definition == null or definition.stages.is_empty():
		return false
	var stage = definition.stages[mini(int(node.get("stage", 0)), definition.stages.size() - 1)]
	var kind: String = str(node.kind)
	var tool: String = ["", "axe", "pickaxe", "shovel"][definition.required_tool]
	var req_tier: int = int(definition.get("required_tool_tier") if definition.get("required_tool_tier") != null else 1)
	if kind in ["berry_bush", "grass", "twig_bush"] and world.has_tool(player, "shovel"):
		tool = "shovel"
		req_tier = 1
	if node.get("depleted", false) and (definition.required_tool == 2 or kind in ["rock", "spirit_rock"]):
		return false
	if int(node.get("stage", 0)) > 0 and kind in ["tree", "berry_bush", "grass", "twig_bush"]:
		tool = "shovel"
		req_tier = 1
	if float(node.get("regrow", 0.0)) > 0.0 and tool != "shovel":
		return false
	if tool != "":
		if float(player.beast_time) > 0.0:
			return false
		if not world.has_tool(player, tool, req_tier):
			if not auto_equip or not world.Access.equip_tool(world, player, tool, req_tier):
				return false
	world.wear_hand(player, 1)
	node.hits = int(node.get("hits", 0)) + 1
	if tool == "shovel":
		world.drop_item("wood" if kind == "tree" else kind, 1, node.position)
		world.remove_entity(node)
	else:
		if node.hits >= int(stage.work_hits):
			node.hits = 0
			node.stage = int(node.get("stage", 0)) + 1
			Rules.drops(world, stage.drops, node.position)
			if kind == "spirit_rock":
				world.drop_item("spirit_stone", 1, node.position)
			if node.stage >= definition.stages.size():
				node.depleted = true
				if kind == "sect_ore":
					world.Karma.add_sin(world, "mine_sect_ore")
				elif kind == "seal_stone":
					world.Karma.add_sin(world, "break_seal_stone")
				node.regrow = definition.regrow_time * world.day_length() / 480.0 if kind != "tree" else 0.0
				if node.regrow > 0.0:
					world.regrowing_uids[int(node.uid)] = true
		world.touch(int(node.uid))
	world.log_event("work", {"uid": node.uid, "hits": node.hits})
	return true
