extends RefCounted

const DevourerConflict = preload("res://world/simulation/traits/devourer_conflict.gd")


static func is_devourable(item_def: ItemDef) -> bool:
	if item_def == null:
		return false
	var id := String(item_def.id)
	if id.begins_with("monster_core") or id.ends_with("_core"):
		return true
	if "essence" in id or id == "yin_soul_crystal" or item_def.get_tag(&"blood") > 0.0:
		return true
	if item_def.get_tag(&"herb") > 0.0 and (
		item_def.get_tag(&"fire") > 0.0
		or item_def.get_tag(&"ice") > 0.0
		or item_def.get_tag(&"yin") > 0.0
		or item_def.get_tag(&"thunder") > 0.0
	):
		return true
	return false


static func element_of(item_def: ItemDef) -> String:
	if item_def.get_tag(&"fire") > 0.0:
		return "fire"
	if item_def.get_tag(&"ice") > 0.0:
		return "ice"
	if item_def.get_tag(&"yin") > 0.0:
		return "yin"
	if item_def.get_tag(&"beast") > 0.0:
		return "beast"
	return "spirit"


static func execute(world, player: Dictionary, args: Dictionary, def) -> bool:
	var inv = world.inventory(player)
	var slot_idx := int(args.get("slot", -1))
	var chosen_def: ItemDef = null
	if slot_idx >= 0 and slot_idx < 15 and not inv.slots[slot_idx].is_empty():
		var candidate := ItemDB.get_item(str(inv.slots[slot_idx].id))
		if is_devourable(candidate):
			chosen_def = candidate
		else:
			slot_idx = -1
	else:
		slot_idx = -1
	if slot_idx < 0:
		for i in 15:
			if inv.slots[i].is_empty():
				continue
			var candidate := ItemDB.get_item(str(inv.slots[i].id))
			if is_devourable(candidate):
				slot_idx = i
				chosen_def = candidate
				break
	if slot_idx < 0 or chosen_def == null:
		return false

	inv.slots[slot_idx].count -= 1
	if inv.slots[slot_idx].count <= 0:
		inv.slots[slot_idx] = {}
	player.inventory = inv.to_dict()

	var elem := element_of(chosen_def)
	var max_hp := float(player.stats.get("max_health", 150.0))
	player.stats["health"] = minf(max_hp, float(player.stats.get("health", max_hp)) + 25.0)
	match elem:
		"fire":
			world.Effects.apply(world, player, "cold_resist", 25.0, 60.0)
			player["warm_time"] = maxf(float(player.get("warm_time", 0.0)), 60.0)
		"ice":
			world.Effects.apply(world, player, "heat_resist", 25.0, 60.0)
			player["cool_time"] = maxf(float(player.get("cool_time", 0.0)), 60.0)
		"yin":
			world.Effects.apply(world, player, "spirit_sight", 1.0, 60.0)
		"beast":
			world.Effects.apply(world, player, "damage_boost", 0.35, 60.0)
		_:
			world.Effects.apply(world, player, "regen", 2.0, 60.0)

	var poison_gain := float(def.cost_amount) if def != null else 20.0
	var new_poison := minf(250.0, float(player.stats.get("poison", 0.0)) + poison_gain)
	player.stats["poison"] = new_poison
	player["poison"] = new_poison
	if new_poison > float(player.get("poison_threshold", 150.0)):
		world.Effects.apply(world, player, "nausea", 1.0, 20.0)

	DevourerConflict.record_and_check(world, player, elem)
	return true
