extends RefCounted


static func throw_talisman(world, player: Dictionary, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	var slot: Dictionary = inv.slots[index]
	if float(slot.get("soak", 0.0)) >= 1.0:
		return false
	var info: Dictionary = world.item(slot.id)
	var effect := str(info.get("talisman_effect", ""))
	if effect.is_empty():
		return false
	if effect in ["true_sight", "ghost_mask", "lightning_ward"]:
		match effect:
			"true_sight":
				world.Effects.apply(world, player, "spirit_sight", 1.0, 60.0)
			"ghost_mask":
				world.Effects.apply(world, player, "stealth", 1.0, 60.0)
			"lightning_ward":
				world.Effects.apply(world, player, "lightning_immune", 1.0, 30.0)
	else:
		var target := _resolve_target(world, player, args)
		if target.is_empty():
			return false
		if effect == "bind":
			world.Effects.apply(world, target, "stun", 1.0, 3.0)
			world.Bosses.on_talisman_hit(world, target, effect)
		elif effect == "frost":
			world.Effects.apply(world, target, "slow", 0.4, 5.0)
			target["channeling"] = 0.0
			world.Bosses.on_talisman_hit(world, target, effect)
			world.touch(int(target.uid))
		else:
			return false
	slot.count -= 1
	if slot.count <= 0:
		inv.slots[index] = {}
	player.inventory = inv.to_dict()
	return true


static func _resolve_target(world, player: Dictionary, args: Dictionary) -> Dictionary:
	var uid = args.get("uid", -1)
	if (uid is int or uid is float) and int(uid) > 0:
		var direct: Dictionary = world.find_any(uid)
		var col: String = world.index.collection_of.get(int(uid), "")
		if not direct.is_empty() and col in ["creatures", "npcs"] and world.near(player, direct, 8.0):
			return direct
	var pos = args.get("position", [])
	if world.valid_position(pos) and world.distance(player.position, pos) <= 8.0:
		var best: Dictionary = {}
		var best_d := 4.0
		for col in ["creatures", "npcs"]:
			for e in world.index.entities_near(pos, 4.0, col):
				if float(e.get("health", 1.0)) <= 0.0:
					continue
				var d: float = world.distance(pos, e.position)
				if d < best_d:
					best_d = d
					best = e
		return best
	return {}


static func apply_moisture(world, delta: float, wet_rate: float) -> void:
	if wet_rate <= 0.0:
		return
	for player in world.state.players.values():
		_wet_slots(player.inventory.get("slots", []), delta * wet_rate)
	for s in world.state.structures:
		if s.kind == "chest":
			if _wet_slots(s.get("slots", []), delta * wet_rate):
				world.touch(int(s.uid))
		elif s.kind == "talisman_chest":
			for slot in s.get("slots", []):
				if slot is Dictionary and float(slot.get("soak", 0.0)) > 0.0:
					slot.soak = 0.0


static func _wet_slots(slots: Array, amount: float) -> bool:
	var changed := false
	for slot in slots:
		if not slot is Dictionary or slot.is_empty():
			continue
		var item_def := ItemDB.get_item(str(slot.get("id", "")))
		if item_def != null and item_def.get_tag(&"paper") > 0.0:
			slot["soak"] = minf(1.0, float(slot.get("soak", 0.0)) + amount)
			changed = true
	return changed
