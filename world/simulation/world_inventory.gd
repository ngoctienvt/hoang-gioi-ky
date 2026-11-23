extends RefCounted

const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")

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
			if not inv.merge_or_swap_slots(source, target):
				return false
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
		if not can_craft_recipe(world, player, recipe):
			return false
		var reqs := PuppeteerCraft.effective_ingredients(player, recipe.resource)
		if not world.craft(inv, recipe, world.tier(player), reqs):
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
			if int(item.get("category", 0)) not in [1, 2] and slot.id not in ["grass_armor", "torch", "hand_warmer"] and part not in ["body", "head"]:
				return false
			inv.slots[index] = inv.equipment.get(part, {})
			inv.equipment[part] = slot
		elif verb == "use":
			var is_water: bool = slot.id == "plain_water" or world.Spring.is_spirit_water(str(slot.id))
			if int(item.get("category", 0)) not in [3, 4] and not is_water:
				return false
			if slot.id == "revival_pill":
				return false
			if int(item.get("category", 0)) == 3 and world.Effects.has(player, "nausea") and not item.get("effects", {}).has("detox"):
				return false
			var stats = world.stats(player)
			var item_def := ItemDB.get_item(slot.id)
			var cdef = world.Abilities.character_def(player)
			var heal_mult := float(cdef.heal_rate) if cdef != null else 1.0
			stats.eat(item_def, float(slot.get("freshness", 1.0)), heal_mult)
			player.stats = stats.to_dict()
			if item_def != null:
				if item_def.warm_effect > 0.0:
					player.warm_time = maxf(float(player.get("warm_time", 0.0)), item_def.warm_effect)
				if item_def.cool_effect > 0.0:
					player.cool_time = maxf(float(player.get("cool_time", 0.0)), item_def.cool_effect)
				world.Effects.apply_item(world, player, item_def)
			if str(slot.id).ends_with("pill"):
				player.poison = stats.poison
				if float(player.poison) > float(player.get("poison_threshold", 50.0)):
					world.Effects.apply(world, player, "nausea", 1.0, 20.0)
			if slot.id == "night_pill":
				player.night_vision = 120.0
			if world.Spring.is_spirit_water(str(slot.id)):
				world.Spring.apply_water_effect(player, world.Spring.water_type_from_item(str(slot.id)))
			slot.count -= 1
			if slot.count <= 0:
				inv.slots[index] = {}
			if is_water:
				world.Access.return_bottle(world, inv, player.position)
		else:
			return false
	player.inventory = inv.to_dict()
	return true


static func can_craft_recipe(world, player: Dictionary, recipe: Dictionary) -> bool:
	if bool(recipe.get("forbidden_unlock", false)):
		var rid := str(recipe.get("id", ""))
		if not rid in world.state.get("forbidden_recipes", []) and not rid in world.state.get("discovered", []):
			return false
	var station := str(recipe.get("station", ""))
	if not station.is_empty():
		var found := false
		for s in world.index.entities_near(player.position, 5.0, "structures"):
			if s.kind == station:
				found = true
				break
		if not found:
			return false
	return true

static func valid_slot(value) -> bool:
	return value is int and value >= 0 and value < InventoryComponent.SLOT_COUNT
