extends RefCounted


static func perform(world, player: Dictionary, target: Dictionary, verb: String, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if verb == "take":
		if target.kind == "lightning_rod":
			if int(target.get("charges", 0)) <= 0 or inv.add_item("charged_thunder_crystal", 1) != 0:
				return false
			target["charges"] = int(target.get("charges", 0)) - 1
			player.inventory = inv.to_dict()
			world.touch(int(target.uid))
			return true
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
		var is_alchemy: bool = target.kind in ["alchemy_furnace", "alchemy_furnace_t2"]
		if not is_alchemy and target.kind != "cooking_pot":
			return false
		var mode := "alchemy" if is_alchemy else "cooking"
		var furnace_tier := int(target.get("tier", 2 if target.kind == "alchemy_furnace_t2" else 1))
		var result: Dictionary = RecipeDB.resolve_alchemy(target.ingredients, world.rng.randf(), furnace_tier, target.solvent) if is_alchemy else RecipeDB.match_recipe(target.ingredients, mode, world.rng.randf())
		target.pending = str(result.get("result", "charred_food"))
		target.remaining = maxf(1, float(result.get("time", 15)))
		target.ingredients = []
		target.solvent = ""
	elif verb == "insert":
		if not world.valid_slot(index) or inv.slots[index].is_empty():
			return false
		var slot: Dictionary = inv.slots[index]
		if target.kind == "water_array":
			if not world.Spring.is_spirit_water(str(slot.id)):
				return false
			target.water_type = world.Spring.water_type_from_item(str(slot.id))
			target.charges = int(target.get("charges", 0)) + 3
			slot.count -= 1
			if slot.count == 0:
				inv.slots[index] = {}
			world.Access.return_bottle(world, inv, player.position)
			player.inventory = inv.to_dict()
			world.touch(int(target.uid))
			return true
		if target.kind not in ["alchemy_furnace", "alchemy_furnace_t2", "cooking_pot"] or target.remaining > 0 or target.output != "":
			return false
		if args.get("solvent", false) == true:
			if target.kind not in ["alchemy_furnace", "alchemy_furnace_t2"] or not world.Spring.is_spirit_water(str(slot.id)) or target.solvent != "":
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
		if args.get("solvent", false) == true:
			world.Access.return_bottle(world, inv, player.position)
	else:
		return false
	player.inventory = inv.to_dict()
	world.touch(int(target.uid))
	return true


static func roast(world, player: Dictionary, target: Dictionary, index) -> bool:
	var inv = world.inventory(player)
	if target.fuel <= 0 or not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	var id: String = inv.slots[index].id
	var recipes := {"spirit_fruit": "roasted_fruit", "mushroom": "roasted_mushroom", "wild_root": "roasted_root", "small_meat": "roasted_meat", "meat": "roasted_meat"}
	if not recipes.has(id):
		return false
	inv.remove_item(id, 1)
	if inv.add_item(recipes[id], 1) != 0:
		return false
	player.inventory = inv.to_dict()
	world.discover(recipes[id])
	return true
