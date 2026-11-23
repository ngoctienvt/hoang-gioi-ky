extends RefCounted


static func step(world, delta: float) -> void:
	var limit: float = world.map_half() - 1.0
	for npc in world.state.get("npcs", []).duplicate():
		npc.cooldown = maxf(0.0, float(npc.get("cooldown", 0.0)) - delta)
		if npc.has("lifetime"):
			npc.lifetime = float(npc.lifetime) - delta
			if npc.lifetime <= 0.0:
				world.remove_entity(npc)
				continue
		var speed_mult: float = world.Effects.step_creature(world, npc, delta)
		if float(npc.get("health", 1.0)) <= 0.0:
			continue
		if npc.get("hostile", false) and speed_mult > 0.0:
			var nearest: Dictionary = {}
			var best_d := 14.0
			for pl in world.state.players.values():
				if pl.ghost or world.Effects.has(pl, "stealth"):
					continue
				var d: float = world.distance(npc.position, pl.position)
				if d < best_d:
					best_d = d
					nearest = pl
			if not nearest.is_empty():
				if best_d < 1.8 and float(npc.cooldown) <= 0.0:
					world.hurt(nearest, float(npc.get("damage", 15.0)))
					npc.cooldown = 1.5
				if world.Creatures.move(npc, nearest.position, 3.6 * speed_mult * delta, limit):
					world.move_entity(npc, npc.position, false)


static func kill(world, npc: Dictionary) -> void:
	for d_id in npc.get("drops", []):
		world.drop_item(str(d_id), 1, npc.position)
	for slot in npc.get("stolen", []):
		world.drop_item(str(slot.id), int(slot.count), npc.position, world.Access.extra(slot))
	world.remove_entity(npc)


static func trade(world, player: Dictionary, args: Dictionary) -> bool:
	var npc: Dictionary = world.index.find_in("npcs", args.get("uid", -1))
	if npc.is_empty() or npc.get("faction", "") != "merchant" or not world.near(player, npc, 4.0):
		return false
	var idx := int(args.get("offer", -1))
	var offers: Array = npc.get("offers", [])
	if idx < 0 or idx >= offers.size():
		return false
	var offer: Dictionary = offers[idx]
	var currency := str(offer.get("currency", "spirit_stone"))
	var price := int(offer.get("price", 1))
	var item_id := str(offer.get("id", ""))
	var count := int(offer.get("count", 1))
	var inv = world.inventory(player)
	if not inv.remove_item(currency, price):
		return false
	if inv.add_item(item_id, count) != 0:
		inv.add_item(currency, price)
		return false
	player.inventory = inv.to_dict()
	world.discover(item_id)
	return true


static func fulfill_request(world, player: Dictionary, args: Dictionary) -> bool:
	var npc: Dictionary = world.index.find_in("npcs", args.get("uid", -1))
	if npc.is_empty() or npc.get("faction", "") != "wanderer" or not world.near(player, npc, 4.0):
		return false
	var inv = world.inventory(player)
	var reqs: Array = npc.get("requests", [])
	if reqs.is_empty():
		return false
	for req in reqs:
		if inv.count_item(str(req.id)) < int(req.count):
			return false
	for req in reqs:
		inv.remove_item(str(req.id), int(req.count))
	inv.add_item("spirit_stone", 3)
	inv.add_item("monster_core", 1)
	player.inventory = inv.to_dict()
	world.Karma.add_fate(world, "help_wanderer")
	world.remove_entity(npc)
	return true


static func invite_guest(world, player: Dictionary, args: Dictionary) -> bool:
	var altar: Dictionary = world.index.find_in("structures", args.get("uid", -1))
	if altar.is_empty() or altar.kind != "guest_altar" or not world.near(player, altar, 4.0):
		return false
	var inv = world.inventory(player)
	if inv.count_item("spirit_stone") < 3 or inv.count_item("incense") < 1:
		return false
	inv.remove_item("spirit_stone", 3)
	inv.remove_item("incense", 1)
	player.inventory = inv.to_dict()
	var faction := "wanderer" if str(args.get("guest_type", "merchant")) == "wanderer" else "merchant"
	var offers := [{"id": "talisman_paper", "count": 4, "currency": "spirit_stone", "price": 1}, {"id": "blood_pill", "count": 1, "currency": "spirit_stone", "price": 2}] if faction == "merchant" else []
	world.Karma.Events.execute(world, _guest_event(faction, offers))
	return true


static func _guest_event(faction: String, offers: Array) -> KarmaEventDef:
	var ev := KarmaEventDef.new()
	ev.kind = "spawn_npc"
	ev.params = {"faction": faction, "offers": offers}
	return ev
