extends RefCounted

const WATER_TYPES := ["thanh_moc", "u_minh", "xich_viem", "loi_tri", "huyen_bang", "co_van"]


static func temper(world, player: Dictionary, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	if float(world.item(inv.slots[index].id).get("damage", 0)) <= 0:
		return false
	var wtype := ""
	var water_slot_idx = args.get("water_slot", -1)
	if world.valid_slot(water_slot_idx) and not inv.slots[water_slot_idx].is_empty():
		var wid := str(inv.slots[water_slot_idx].id)
		if world.Spring.is_spirit_water(wid):
			wtype = world.Spring.water_type_from_item(wid)
			inv.slots[water_slot_idx].count -= 1
			if inv.slots[water_slot_idx].count <= 0:
				inv.slots[water_slot_idx] = {}
	if wtype.is_empty():
		if inv.remove_item("spirit_water", 1):
			wtype = "thanh_moc"
		else:
			for wt in WATER_TYPES:
				if inv.remove_item("spirit_water_" + wt, 1):
					wtype = wt
					break
	if wtype.is_empty():
		return false
	world.Access.return_bottle(world, inv, player.position)
	var weapon: Dictionary = inv.slots[index]
	weapon.erase("vitality_hits")
	if wtype == "co_van":
		weapon.erase("temper")
	else:
		weapon["temper"] = {"type": wtype, "hits": 20}
	player.inventory = inv.to_dict()
	return true


static func get_temper_type(hand: Dictionary) -> String:
	if hand.is_empty():
		return ""
	var temper_data = hand.get("temper", {})
	if temper_data is Dictionary and int(temper_data.get("hits", 0)) > 0:
		return str(temper_data.get("type", ""))
	if int(hand.get("vitality_hits", 0)) > 0:
		return "thanh_moc"
	return ""


static func apply_hit(world, player: Dictionary, target: Dictionary, hand: Dictionary) -> void:
	if hand.is_empty():
		return
	var ttype := get_temper_type(hand)
	if ttype.is_empty():
		return
	match ttype:
		"thanh_moc":
			player.stats.health = minf(float(player.stats.get("max_health", world.Rules.BASE_MAX_HEALTH)), float(player.stats.health) + 2.0)
		"u_minh":
			pass # Phá Hồn: allows hitting phantom/wraith targets in world_combat.gd
		"xich_viem":
			world.Effects.apply(world, target, "burn", 4.0, 3.0)
		"loi_tri":
			if world.rng.randf() < 0.2:
				world.Effects.apply(world, target, "stun", 1.0, 1.0)
		"huyen_bang":
			world.Effects.apply(world, target, "slow", 0.4, 3.0)
	if hand.has("temper") and hand.temper is Dictionary:
		hand.temper.hits = int(hand.temper.get("hits", 0)) - 1
		if int(hand.temper.hits) <= 0:
			hand.erase("temper")
	elif int(hand.get("vitality_hits", 0)) > 0:
		hand.vitality_hits -= 1
		if int(hand.vitality_hits) <= 0:
			hand.erase("vitality_hits")
