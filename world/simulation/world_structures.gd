extends RefCounted

const Stations = preload("res://world/simulation/world_stations.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")

const CHEST_KINDS := ["chest", "ice_cellar", "talisman_chest", "resurrection_altar"]
const FUEL_ITEMS := {"wood": 90.0, "twig": 30.0, "grass": 15.0, "bamboo": 60.0, "damp_wood": 60.0, "charcoal": 120.0, "hard_wood": 110.0, "frost_wood": 90.0}


static func perform(world, player: Dictionary, verb: String, args: Dictionary) -> bool:
	if verb == "place":
		return place(world, player, args)
	var uid = args.get("uid", -1)
	if verb == "fuel":
		var puppet: Dictionary = world.index.find_in("puppets", uid)
		if not puppet.is_empty() and world.near(player, puppet, 3.5):
			return _fuel_puppet(world, player, puppet, args.get("slot", -1))
	var target: Dictionary = world.index.find_in("structures", uid)
	if target.is_empty() or not world.near(player, target, 3.5):
		return false
	if verb == "take" and target.kind == "farm":
		return world.Spring.perform(world, player, "water", {"uid": target.uid, "mode": "harvest"})
	if verb in ["take", "cook", "roast", "insert"]:
		return Stations.perform(world, player, target, verb, args)
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if verb == "fuel":
		if not world.valid_slot(index) or inv.slots[index].is_empty():
			return false
		var slot: Dictionary = inv.slots[index]
		if target.kind == "light_pillar":
			if slot.id != "spirit_stone":
				return false
			target.fuel = float(target.get("fuel", 0.0)) + world.day_length()
		elif target.kind in ["campfire", "firepit"] and FUEL_ITEMS.has(slot.id):
			target.fuel = float(target.get("fuel", 0.0)) + float(FUEL_ITEMS[slot.id])
		else:
			return false
		_consume_one(inv, index)
	elif verb == "chest_put":
		if target.kind not in CHEST_KINDS or not world.valid_slot(index) or inv.slots[index].is_empty():
			return false
		var slot: Dictionary = inv.slots[index]
		var extra: Dictionary = world.Access.extra(slot)
		if target.kind == "talisman_chest":
			extra.erase("soak")
		var storage = world.inventory({"inventory": {"slots": target.slots, "equipment": {}}})
		if storage.add_item(slot.id, 1, extra) != 0:
			return false
		target.slots = storage.to_dict().slots
		_consume_one(inv, index)
	elif verb == "chest_take":
		if target.kind not in CHEST_KINDS or not world.valid_slot(index) or index >= target.slots.size() or target.slots[index].is_empty():
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
	world.touch(int(target.uid))
	return true


static func _fuel_puppet(world, player: Dictionary, puppet: Dictionary, index) -> bool:
	var inv = world.inventory(player)
	if not world.valid_slot(index) or inv.slots[index].is_empty() or inv.slots[index].id != "spirit_stone":
		return false
	_consume_one(inv, index)
	puppet.fuel = float(puppet.get("fuel", 0.0)) + world.day_length() * 0.5
	if str(puppet.get("state", "")) == "out_of_fuel":
		puppet.state = "idle"
	player.inventory = inv.to_dict()
	world.touch(int(puppet.uid))
	return true


static func _consume_one(inv, index: int) -> void:
	inv.slots[index].count -= 1
	if inv.slots[index].count <= 0:
		inv.slots[index] = {}


static func place(world, player: Dictionary, args: Dictionary) -> bool:
	var recipe: Dictionary = world.recipe(args.get("recipe", ""))
	var kind: String = world.structure_kind(recipe)
	var pos = args.get("position", [])
	if kind == "" or not world.valid_position(pos) or not world.near(player, {"position": pos}, 5):
		return false
	if not world.Items.can_craft_recipe(world, player, recipe):
		return false
	if kind.begins_with("puppet_"):
		return world.Puppets.deploy_from_recipe(world, player, recipe, pos)
	for target in world.index.entities_near(pos, 3.5):
		var col: String = world.index.collection_of.get(int(target.uid), "")
		if col not in ["structures", "nodes"]:
			continue
		if world.distance(pos, target.position) < (3.0 if target.kind == "spring" else 1.5):
			return false
	var inv = world.inventory(player)
	var reqs := PuppeteerCraft.effective_ingredients(player, recipe.resource)
	if not world.craft(inv, recipe, world.tier(player), reqs):
		return false
	inv.remove_item(str(recipe.get("result", kind)), int(recipe.get("count", 1)))
	player.inventory = inv.to_dict()
	var structure: Dictionary = world.entity(kind, pos)
	structure.merge({"health": 200.0, "fuel": 90.0 if kind in ["campfire", "firepit"] else 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "crop": "", "growth": 0.0})
	if kind == "alchemy_furnace_t2":
		structure["tier"] = 2
	elif kind == "talisman_chest":
		structure["fireproof"] = true
		structure["anti_theft"] = true
		structure["moisture_proof"] = true
	elif kind == "stake":
		structure["radius"] = 8.0
	elif kind == "water_array":
		structure["water_type"] = ""
		structure["charges"] = 0
		structure["last_water_day"] = 0
	structure.slots.resize(InventoryComponent.SLOT_COUNT)
	for index in range(InventoryComponent.SLOT_COUNT):
		structure.slots[index] = {}
	world.add_entity("structures", structure)
	world.discover(str(recipe.get("id", kind)))
	return true


static func has_water_array_near(world, pos: Array, radius: float = 8.0) -> bool:
	for s in world.index.entities_near(pos, radius, "structures"):
		if s.kind == "water_array" and int(s.get("charges", 0)) > 0:
			return true
	return false


static func step(world, delta: float) -> void:
	var day := int(world.state.clock.get("day", 1))
	for target in world.state.structures:
		var changed := false
		if float(target.fuel) > 0.0:
			target.fuel = maxf(0.0, float(target.fuel) - delta)
			changed = true
		if float(target.remaining) > 0.0:
			target.remaining = maxf(0.0, float(target.remaining) - delta)
			changed = true
			if target.remaining == 0.0:
				target.output = target.pending
				world.discover(target.output)
		if target.kind == "talisman_chest":
			for slot in target.slots:
				if slot is Dictionary and float(slot.get("soak", 0.0)) > 0.0:
					slot.soak = 0.0
					changed = true
		if target.kind == "water_array" and int(target.get("charges", 0)) > 0 and str(target.get("water_type", "")) != "" and int(target.get("last_water_day", 0)) < day:
			if _water_nearby_farms(world, target):
				target.charges = maxi(0, int(target.charges) - 1)
				target.last_water_day = day
				changed = true
		if changed:
			world.touch(int(target.uid))


static func _water_nearby_farms(world, array_struct: Dictionary) -> bool:
	var watered_any := false
	var wtype := str(array_struct.get("water_type", ""))
	if wtype == "xich_viem":
		return false
	for s in world.index.entities_near(array_struct.position, 6.0, "structures"):
		if s.kind == "farm" and str(s.get("crop", "")) != "" and not s.get("watered", false):
			world.Farming.apply_water_to_farm(world, s, wtype)
			world.touch(int(s.uid))
			watered_any = true
	return watered_any
