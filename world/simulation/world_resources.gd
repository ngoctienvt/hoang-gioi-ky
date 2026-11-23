extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

static func step(world, delta: float) -> void:
	for node in world.state.nodes:
		if float(node.get("regrow", 0)) > 0:
			node.regrow = maxf(0, node.regrow - delta)
			if node.regrow == 0:
				node.stage = 0
				node.hits = 0
				node.depleted = false
		if node.get("sapling", false):
			node.age += delta
			if node.age >= world.day_length() * 2:
				node.sapling = false
				node.stage = 0

static func work(world, player: Dictionary, node: Dictionary) -> bool:
	if node.is_empty() or not node.kind in Rules.NODE_KINDS or node.get("sapling", false):
		return false
	var definition = Rules.node(node.kind)
	if definition == null or definition.stages.is_empty():
		return false
	var stage = definition.stages[mini(int(node.get("stage", 0)), definition.stages.size() - 1)]
	var kind: String = node.kind
	var tool: String = ["", "axe", "pickaxe", "shovel"][definition.required_tool]
	if kind in ["berry_bush", "grass", "twig_bush"] and world.has_tool(player, "shovel"):
		tool = "shovel"
	if node.get("depleted", false) and kind in ["rock", "spirit_rock"]:
		return false
	if int(node.get("stage", 0)) > 0 and kind in ["tree", "berry_bush", "grass", "twig_bush"]:
		tool = "shovel"
	if float(node.get("regrow", 0)) > 0 and tool != "shovel":
		return false
	if tool != "" and (not world.has_tool(player, tool) or float(player.beast_time) > 0):
		return false
	world.wear_hand(player, 1)
	node.hits = int(node.get("hits", 0)) + 1
	if tool == "shovel":
		world.drop_item("wood" if kind == "tree" else kind, 1, node.position)
		world.state.nodes.erase(node)
	elif node.hits >= int(stage.work_hits):
		node.hits = 0
		node.stage += 1
		Rules.drops(world, stage.drops, node.position)
		if kind == "spirit_rock":
			world.drop_item("spirit_stone", 1, node.position)
		if node.stage >= definition.stages.size():
			node.depleted = true
			node.regrow = definition.regrow_time * world.day_length() / 480.0 if kind != "tree" else 0.0
	world.log_event("work", {"uid": node.uid, "hits": node.hits})
	return true
