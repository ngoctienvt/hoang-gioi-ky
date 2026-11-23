extends RefCounted

static func step(world, delta: float) -> void:
	var living = 0
	for player in world.state.players.values():
		for key in ["attack_cd", "work_cd", "ability_cd", "sense_cd", "beast_time", "sense_time", "night_vision", "spring_heal", "hit_flash"]:
			player[key] = maxf(0, float(player.get(key, 0)) - delta)
		if player.ghost:
			continue
		living += 1
		var stats = world.stats(player)
		var near_fire = false
		var lit = player.night_vision > 0
		for structure in world.state.structures:
			if structure.fuel > 0 and world.near(player, structure, 7):
				lit = true
				near_fire = true
		var hand: Dictionary = player.inventory.equipment.get("hand", {})
		if hand.get("id", "") == "torch":
			lit = true
			player.torch_wear = float(player.get("torch_wear", 0)) + delta
			if player.torch_wear >= 1:
				world.wear_hand(player, int(player.torch_wear))
				player.torch_wear = 0.0
		var dark = world.state.clock.get("phase", "day") == "night" and not lit
		stats.tick(delta, dark, near_fire)
		if player.beast_time > 0:
			stats.stamina = maxf(0, stats.stamina - delta * 2)
		if player.spring_heal > 0:
			stats.health = minf(float(player.stats.get("max_health", 150)), stats.health + delta)
		player.poison = stats.poison
		player.stats = stats.to_dict()
		player.darkness = float(player.get("darkness", 0)) + delta if dark else 0.0
		player.warning = stats.stamina < 25 or stats.dao < 20
		if (stats.stamina <= 5 or stats.dao <= 5) and player.beast_time <= 0:
			player.mad = true
			player.beast_time = 12.0
			clear_hand(world, player)
		elif player.beast_time <= 0:
			player.mad = false
		if player.mad and player.attack_cd <= 0:
			for peer in world.state.players:
				var other: Dictionary = world.state.players[peer]
				if other != player and not other.ghost and world.near(player, other, 2.8):
					world.Combat.attack(world, player, {"peer_id": int(peer)})
					break
		if player.stats.health <= 0:
			die(world, player)
	if living == 0 and not world.state.players.is_empty():
		if world.state.options.get("death_mode", world.state.options.get("all_dead", "continue")) == "reset":
			world.state.reset_requested = true
		else:
			for player in world.state.players.values():
				revive(world, player)

static func ability(world, player: Dictionary, args: Dictionary) -> bool:
	var name = args.get("name", "")
	var stats = player.stats
	if name == "sense" and player.sense_cd <= 0 and stats.stamina >= 10:
		stats.stamina -= 10
		player.sense_cd = 30.0
		player.sense_time = 8.0
		return true
	if name == "beast" and player.ability_cd <= 0 and stats.stamina >= 30:
		stats.stamina -= 30
		player.ability_cd = 90.0
		player.beast_time = 15.0
		clear_hand(world, player)
		return true
	return false

static func clear_hand(world, player: Dictionary) -> void:
	var inv = world.inventory(player)
	var hand: Dictionary = inv.equipment.hand
	if not hand.is_empty():
		if inv.add_item(hand.id, hand.count, world.Access.extra(hand)) > 0:
			world.drop_item(hand.id, hand.count, player.position, hand)
		inv.equipment.hand = {}
	player.inventory = inv.to_dict()

static func die(world, player: Dictionary) -> void:
	for slot in player.inventory.slots + player.inventory.equipment.values():
		if not slot.is_empty():
			world.drop_item(slot.id, slot.count, player.position, slot)
	player.inventory = world.inventory({}).to_dict()
	player.ghost = true
	player.beast_time = 0.0
	world.log_event("player_death", {"name": player.name})

static func revive(world, player: Dictionary) -> void:
	player.ghost = false
	player.deaths = mini(2, int(player.get("deaths", 0)) + 1)
	player.position = [0.0, 0.0, 0.0]
	player.stats.max_health = 150.0 * (1 - player.deaths * 0.25)
	player.stats.revivals = player.deaths
	player.stats.health = player.stats.max_health * 0.6
	player.stats.stamina = 80.0
	player.stats.dao = 50.0
	player.recovery = world.day_length()
	world.log_event("revive", {"name": player.name})

static func request_revive(world, player: Dictionary, args: Dictionary) -> bool:
	var target = world.state.players.get(str(args.get("peer_id", -1)), {})
	if player.ghost:
		target = player
	if target.is_empty() or not target.ghost or not world.near(player, target, 3):
		return false
	var inv = world.inventory(player)
	if player.ghost:
		var altar = world.find_entity(world.state.structures, args.get("uid", -1))
		if altar.is_empty() or altar.kind != "resurrection_altar" or not world.near(player, altar, 3):
			return false
		var storage = world.inventory({"inventory": {"slots": altar.slots}})
		if not storage.remove_item("spirit_stone", 2):
			return false
		altar.slots = storage.to_dict().slots
	elif not inv.remove_item("revival_pill", 1):
		return false
	player.inventory = inv.to_dict()
	var revival_position: Array = target.position.duplicate()
	revive(world, target)
	target.position = revival_position
	return true
