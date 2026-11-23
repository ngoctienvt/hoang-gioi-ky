extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")
const Temperature = preload("res://world/simulation/world_temperature.gd")
const Weather = preload("res://world/simulation/world_weather.gd")
const NAUSEA_HEAL_RATE := 0.5  # nausea halves healing (GDD 6.5 "chậm hồi")


static func step(world, delta: float) -> void:
	for trap_uid in world.active_traps.keys():
		var trap: Dictionary = world.index.find(trap_uid)
		if trap.is_empty():
			world.active_traps.erase(trap_uid)
			continue
		trap.cooldown = maxf(0.0, float(trap.get("cooldown", 0.0)) - delta)
		if trap.cooldown <= 0.0:
			world.active_traps.erase(trap_uid)
			world.touch(int(trap_uid))

	var living := 0
	for player in world.state.players.values():
		for key in Rules.PLAYER_TIMERS:
			player[key] = maxf(0, float(player.get(key, 0)) - delta)
		if player.ghost:
			continue
		living += 1
		player.biome_timer = float(player.get("biome_timer", 0.0)) + delta
		if player.biome_timer >= 1.0:
			player.biome_timer = 0.0
			player.biome = world.biome_at(player.position)
		# Timed effects (regen, stealth, burn, nausea...) count down and apply before the stats tick,
		# so burn damage dealt here is not overwritten by the stats written back below.
		world.Effects.step_player(world, player, delta)
		var stats = world.stats(player)
		var near_fire := false
		var lit: bool = player.night_vision > 0
		for structure in world.index.entities_near(player.position, 7.0, "structures"):
			if float(structure.get("fuel", 0.0)) > 0.0:
				lit = true
				near_fire = true
				break
		var hand: Dictionary = player.inventory.equipment.get("hand", {})
		if hand.get("id", "") == "torch":
			lit = true
			player.torch_wear = float(player.get("torch_wear", 0)) + delta
			if player.torch_wear >= 1:
				world.wear_hand(player, int(player.torch_wear))
				player.torch_wear = 0.0
		elif hand.get("id", "") == "hand_warmer" and int(hand.get("durability", 0)) > 0:
			lit = true
		var dark: bool = world.state.clock.get("phase", "day") == "night" and not lit
		var dark_for_stats: bool = dark and not world.Skills.has_imprint_effect(player, "no_dark_dao_drain")
		stats.tick(delta, dark_for_stats, near_fire)
		var modifiers := {"health": 0.0, "stamina": 0.0, "dao": 0.0}
		Temperature.step_player(world, player, stats, delta, modifiers)
		Weather.apply_player_weather(world, player, delta, modifiers)
		if str(player.get("biome", "")) == "nether_swamp" and not world.Effects.has(player, "poison_immune"):
			# The swamp's toxic miasma wears the Dao Heart; Tị Độc Đan keeps it out.
			modifiers.dao -= 0.5 * delta
		if player.spring_heal > 0:
			modifiers.health += delta
		if world.Effects.has(player, "regen"):
			modifiers.health += world.Effects.magnitude(player, "regen", 2.0) * delta
		world.Abilities.step_player(world, player, stats, delta, modifiers)
		var cdef = world.Abilities.character_def(player)
		if cdef != null and float(modifiers.health) > 0.0:
			modifiers.health = float(modifiers.health) * float(cdef.heal_rate)
		if world.Effects.has(player, "nausea") and float(modifiers.health) > 0.0:
			modifiers.health = float(modifiers.health) * NAUSEA_HEAL_RATE
		stats.health = clampf(stats.health + float(modifiers.health), 0.0, float(player.stats.get("max_health", Rules.BASE_MAX_HEALTH)))
		stats.stamina = clampf(stats.stamina + float(modifiers.stamina), 0.0, 150.0)
		stats.dao = clampf(stats.dao + float(modifiers.dao), 0.0, 100.0)
		player.poison = stats.poison
		player.stats = stats.to_dict()
		var on_mud := false
		for near_node in world.index.entities_near(player.position, 1.8, "nodes"):
			var nkind := str(near_node.get("kind", ""))
			if nkind == "mud":
				on_mud = true
			elif nkind == "floor_trap" and float(near_node.get("cooldown", 0.0)) <= 0.0 and world.distance(player.position, near_node.position) <= 1.2:
				if not world.Skills.has_imprint_effect(player, "trap_immunity"):
					near_node.cooldown = 5.0
					world.active_traps[int(near_node.uid)] = true
					world.touch(int(near_node.uid))
					world.hurt(player, 15.0)
		player.in_mud = on_mud and not world.Skills.has_imprint_effect(player, "trap_immunity")
		player.darkness = float(player.get("darkness", 0)) + delta if dark else 0.0
		player.warning = stats.stamina < 25 or stats.dao < 20
		if player.stats.health <= 0:
			die(world, player)
	if living == 0 and not world.state.players.is_empty():
		if world.state.options.get("death_mode", world.state.options.get("all_dead", "continue")) == "reset":
			world.state.reset_requested = true
		else:
			for player in world.state.players.values():
				revive(world, player)


static func ability(world, player: Dictionary, args: Dictionary) -> bool:
	return world.Abilities.ability(world, player, args)


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
	if player.get("in_secret_realm", false):
		var ret: Array = player.get("realm_return_pos", [0.0, 0.0, 0.0])
		player.position = ret.duplicate() if ret.size() == 3 else [0.0, 0.0, 0.0]
		player["in_secret_realm"] = false
	else:
		player.position = [0.0, 0.0, 0.0]
	var base_hp := float(player.stats.get("base_max_health", Rules.BASE_MAX_HEALTH))
	player.stats.max_health = base_hp * (1.0 - player.deaths * 0.25)
	player.stats.revivals = player.deaths
	player.stats.health = player.stats.max_health * 0.6
	player.stats.stamina = 80.0
	player.stats.dao = 50.0
	player.recovery = world.day_length()
	world.log_event("revive", {"name": player.name})


static func request_revive(world, player: Dictionary, args: Dictionary) -> bool:
	var target: Dictionary = world.state.players.get(str(args.get("peer_id", -1)), {})
	if player.ghost:
		target = player
	if target.is_empty() or not target.ghost or not world.near(player, target, 3):
		return false
	var inv = world.inventory(player)
	if player.ghost:
		var altar: Dictionary = world.index.find_in("structures", args.get("uid", -1))
		if altar.is_empty() or altar.kind != "resurrection_altar" or not world.near(player, altar, 3):
			return false
		var storage = world.inventory({"inventory": {"slots": altar.slots}})
		if not storage.remove_item("spirit_stone", 2):
			return false
		altar.slots = storage.to_dict().slots
		world.touch(int(altar.uid))
	elif not inv.remove_item("revival_pill", 1):
		return false
	player.inventory = inv.to_dict()
	var revival_position: Array = target.position.duplicate()
	revive(world, target)
	target.position = revival_position
	return true
