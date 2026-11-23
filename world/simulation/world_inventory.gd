extends RefCounted

static func perform(world, player: Dictionary, verb: String, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if verb == "unequip":
		var part = args.get("slot", "")
		if part not in ["hand", "body", "head"] or inv.equipment[part].is_empty():
			return false
		var worn: Dictionary = inv.equipment[part]
		if inv.add_item(worn.id, worn.count, world.Access.extra(worn)) != 0:
			return false
		inv.equipment[part] = {}
	elif verb in ["move_slot", "split"]:
		var source = args.get("from", -1)
		var target = args.get("to", -1)
		if not valid_slot(source) or not valid_slot(target) or source == target:
			return false
		if verb == "move_slot":
			var old = inv.slots[target]
			inv.slots[target] = inv.slots[source]
			inv.slots[source] = old
		else:
			var amount = args.get("count", 1)
			if not world.valid_count(amount) or inv.slots[source].is_empty() or not inv.slots[target].is_empty():
				return false
			if amount >= int(inv.slots[source].count):
				return false
			inv.slots[target] = inv.slots[source].duplicate(true)
			inv.slots[target].count = amount
			inv.slots[source].count -= amount
	elif verb == "craft":
		var recipe = world.recipe(args.get("recipe", ""))
		if recipe.is_empty() or world.structure_kind(recipe) != "":
			return false
		if not world.craft(inv, recipe, world.tier(player)):
			return false
		world.discover(str(recipe.get("id", recipe.get("result", ""))))
	else:
		if not valid_slot(index) or inv.slots[index].is_empty():
			return false
		var slot: Dictionary = inv.slots[index]
		var item = world.item(slot.id)
		if verb == "drop":
			var count = args.get("count", 1)
			if not world.valid_count(count) or count > int(slot.count):
				return false
			world.drop_item(slot.id, count, player.position, slot)
			slot.count -= count
			if slot.count == 0:
				inv.slots[index] = {}
		elif verb == "equip":
			var part = str(item.get("equipment_slot", item.get("slot", "hand")))
			if part not in ["hand", "body", "head"] or float(player.beast_time) > 0:
				return false
			if int(item.get("category", 0)) not in [1, 2] and slot.id not in ["grass_armor", "torch"]:
				return false
			inv.slots[index] = inv.equipment.get(part, {})
			inv.equipment[part] = slot
		elif verb == "use":
			if int(item.get("category", 0)) not in [3, 4]:
				return false
			if slot.id == "revival_pill":
				return false
			var stats = world.stats(player)
			stats.eat(ItemDB.get_item(slot.id))
			player.stats = stats.to_dict()
			if str(slot.id).ends_with("pill"):
				player.poison = stats.poison
			if slot.id == "night_pill":
				player.night_vision = 120.0
			slot.count -= 1
			if slot.count <= 0:
				inv.slots[index] = {}
		else:
			return false
	player.inventory = inv.to_dict()
	return true

static func valid_slot(value) -> bool:
	return value is int and value >= 0 and value < 15
