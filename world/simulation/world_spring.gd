extends RefCounted

static func perform(world, player: Dictionary, verb: String, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var target = world.find_any(args.get("uid", -1))
	if verb == "temper":
		var index = args.get("slot", -1)
		if not world.valid_slot(index) or inv.slots[index].is_empty() or float(world.item(inv.slots[index].id).get("damage", 0)) <= 0:
			return false
		if not inv.remove_item("spirit_water", 1):
			return false
		world.Access.return_bottle(world, inv, player.position)
		inv.slots[index].vitality_hits = 20
	elif verb == "plant":
		var index = args.get("slot", -1)
		if not world.valid_slot(index) or inv.slots[index].is_empty():
			return false
		var id: String = inv.slots[index].id
		if id in ["pinecone", "berry_bush", "grass", "twig_bush"]:
			var pos = args.get("position", [])
			if not world.valid_position(pos) or not world.near(player, {"position": pos}, 4):
				return false
			for node in world.state.nodes + world.state.structures:
				if world.distance(node.position, pos) < 1.5:
					return false
			var node = world.entity("tree" if id == "pinecone" else id, pos)
			node.merge({"stage": 0, "hits": 0, "regrow": 0.0, "age": 0.0, "sapling": id == "pinecone"})
			world.state.nodes.append(node)
		elif id in ["seed", "herb"] and not target.is_empty() and target.kind == "farm" and world.near(player, target, 3) and target.crop == "":
			target.crop = "herb"
			target.growth = 0.0
			target.watered = false
		else:
			return false
		inv.remove_item(id, 1)
	elif verb == "water":
		if target.is_empty() or not world.near(player, target, 3):
			return false
		var mode = args.get("mode", "fill" if target.kind == "spring" else "water")
		if target.kind == "spring":
			if mode == "fill":
				if not inv.remove_item("water_bottle", 1) or inv.add_item("spirit_water", 1, {"expires": world.elapsed() + world.day_length() * 3}) != 0:
					return false
			elif mode in ["drink", "bathe"]:
				player.spring_heal = 30.0
			else:
				return false
		elif target.kind == "farm":
			if mode == "harvest" and target.growth >= world.day_length():
				var result = "mutant_fruit" if target.get("watered", false) and world.rng.randf() < 0.3 else "herb"
				if inv.add_item(result, 2) != 0:
					return false
				target.crop = ""
				target.growth = 0.0
				target.fertilized = false
				target.watered = false
			elif target.crop != "" and mode in ["water", "fertilize"]:
				if target.get("fertilized" if mode == "fertilize" else "watered", false):
					return false
				if not inv.remove_item("waste_pill" if mode == "fertilize" else "spirit_water", 1):
					return false
				if mode == "water":
					world.Access.return_bottle(world, inv, player.position)
				target["fertilized" if mode == "fertilize" else "watered"] = true
				target.growth += world.day_length() * 0.3
			else:
				return false
		else:
			return false
	else:
		return false
	player.inventory = inv.to_dict()
	return true

static func step(world, delta: float) -> void:
	for target in world.state.structures:
		expire_slots(target.slots, world.elapsed())
		if target.solvent == "spirit_water" and float(target.get("solvent_expires", INF)) <= world.elapsed():
			target.solvent = "plain_water"
		if target.kind == "farm" and target.crop != "":
			target.growth += delta * (1.5 if target.get("watered", false) else 1.0)
	for player in world.state.players.values() + world.state.offline_players.values():
		expire_slots(player.inventory.slots, world.elapsed())
	for drop in world.state.drops:
		if drop.id == "spirit_water" and float(drop.extra.get("expires", INF)) <= world.elapsed():
			drop.id = "plain_water"
			drop.extra.erase("expires")

static func expire_slots(slots: Array, time: float) -> void:
	for slot in slots:
		if slot.get("id", "") == "spirit_water" and float(slot.get("expires", INF)) <= time:
			slot.id = "plain_water"
			slot.erase("expires")
