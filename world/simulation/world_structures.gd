extends RefCounted

static func perform(world, player: Dictionary, verb: String, args: Dictionary) -> bool:
	if verb == "place":
		return place(world, player, args)
	var target = world.find_entity(world.state.structures, args.get("uid", -1))
	if target.is_empty() or not world.near(player, target, 3.5):
		return false
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if verb == "take" and target.kind == "farm":
		return world.Spring.perform(world, player, "water", {"uid": target.uid, "mode": "harvest"})
	if verb == "take":
		if target.output == "" or inv.add_item(target.output, 1) != 0:
			return false
		target.output = ""
	elif verb in ["cook", "roast"]:
		if target.kind in ["campfire", "firepit"]:
			return roast(world, player, target, index)
		if verb == "roast":
			return false
		if target.remaining > 0 or target.output != "" or target.ingredients.size() != 4:
			return false
		var mode = "alchemy" if target.kind == "alchemy_furnace" else "cooking"
		if target.kind not in ["alchemy_furnace", "cooking_pot"]:
			return false
		var result = RecipeDB.resolve_alchemy(target.ingredients, world.rng.randf(), int(target.get("tier", 1)), target.solvent) if mode == "alchemy" else RecipeDB.match_recipe(target.ingredients, mode, world.rng.randf())
		target.pending = str(result.get("result", "charred_food"))
		target.remaining = maxf(1, float(result.get("time", 15)))
		target.ingredients = []
		target.solvent = ""
	elif verb in ["insert", "fuel", "chest_put"]:
		if not world.valid_slot(index) or inv.slots[index].is_empty():
			return false
		var slot: Dictionary = inv.slots[index]
		if verb == "fuel":
			if target.kind not in ["campfire", "firepit"] or slot.id not in ["wood", "twig", "grass", "bamboo"]:
				return false
			target.fuel += {"wood": 90, "twig": 30, "grass": 15, "bamboo": 60}[slot.id]
		elif verb == "chest_put":
			if target.kind not in ["chest", "resurrection_altar"]:
				return false
			var storage = world.inventory({"inventory": {"slots": target.slots, "equipment": {}}})
			if storage.add_item(slot.id, 1, world.Access.extra(slot)) != 0:
				return false
			target.slots = storage.to_dict().slots
		else:
			if target.kind not in ["alchemy_furnace", "cooking_pot"] or target.remaining > 0 or target.output != "":
				return false
			if args.get("solvent", false) == true:
				if target.kind != "alchemy_furnace" or slot.id != "spirit_water" or target.solvent != "":
					return false
				target.solvent = slot.id
				target.solvent_expires = slot.get("expires", world.elapsed() + world.day_length() * 3)
			else:
				if target.ingredients.size() >= 4 or world.item(slot.id).get("tags", {}).is_empty():
					return false
				target.ingredients.append(slot.id)
		slot.count -= 1
		if slot.count == 0:
			inv.slots[index] = {}
		if verb == "insert" and args.get("solvent", false) == true:
			world.Access.return_bottle(world, inv, player.position)
	elif verb == "chest_take":
		if target.kind not in ["chest", "resurrection_altar"] or not world.valid_slot(index) or target.slots[index].is_empty():
			return false
		var slot: Dictionary = target.slots[index]
		if inv.add_item(slot.id, 1, world.Access.extra(slot)) != 0:
			return false
		slot.count -= 1
		if slot.count == 0:
			target.slots[index] = {}
	else:
		return false
	player.inventory = inv.to_dict()
	return true

static func roast(world, player: Dictionary, target: Dictionary, index) -> bool:
	var inv = world.inventory(player)
	if target.fuel <= 0 or not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	var id: String = inv.slots[index].id
	var recipes = {"spirit_fruit": "roasted_fruit", "mushroom": "roasted_mushroom", "wild_root": "roasted_root", "small_meat": "roasted_meat", "meat": "roasted_meat"}
	if not recipes.has(id):
		return false
	inv.remove_item(id, 1)
	if inv.add_item(recipes[id], 1) != 0:
		return false
	player.inventory = inv.to_dict()
	world.discover(recipes[id])
	return true

static func place(world, player: Dictionary, args: Dictionary) -> bool:
	var recipe = world.recipe(args.get("recipe", ""))
	var kind: String = world.structure_kind(recipe)
	var pos = args.get("position", [])
	if kind == "" or not world.valid_position(pos) or not world.near(player, {"position": pos}, 5):
		return false
	for target in world.state.structures + world.state.nodes:
		if world.distance(pos, target.position) < (3.0 if target.kind == "spring" else 1.5):
			return false
	var inv = world.inventory(player)
	if not world.craft(inv, recipe, world.tier(player)):
		return false
	inv.remove_item(str(recipe.get("result", kind)), int(recipe.get("count", 1)))
	player.inventory = inv.to_dict()
	var structure = world.entity(kind, pos)
	structure.merge({"health": 200.0, "fuel": 90.0 if kind in ["campfire", "firepit"] else 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "crop": "", "growth": 0.0})
	structure.slots.resize(15)
	for index in range(15):
		structure.slots[index] = {}
	world.state.structures.append(structure)
	world.discover(str(recipe.get("id", kind)))
	return true

static func step(world, delta: float) -> void:
	for target in world.state.structures:
		target.fuel = maxf(0, target.fuel - delta)
		if target.remaining > 0:
			target.remaining = maxf(0, target.remaining - delta)
			if target.remaining == 0:
				target.output = target.pending
				world.discover(target.output)
