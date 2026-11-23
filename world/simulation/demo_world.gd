class_name DemoWorld
extends RefCounted

const Inventory = preload("res://components/inventory_component.gd")
const Stats = preload("res://components/survival_stats.gd")
const SeedWorld = preload("res://world/simulation/world_seed.gd")
const Resources = preload("res://world/simulation/world_resources.gd")
const Structures = preload("res://world/simulation/world_structures.gd")
const Items = preload("res://world/simulation/world_inventory.gd")
const Spring = preload("res://world/simulation/world_spring.gd")
const Combat = preload("res://world/simulation/world_combat.gd")
const Creatures = preload("res://world/simulation/world_creatures.gd")
const Access = preload("res://world/simulation/world_access.gd")
var life = preload("res://world/simulation/world_life.gd")
var state: Dictionary = {}
var rng = RandomNumberGenerator.new()
var next_uid = 1

func initialize(seed_value: int, options: Dictionary) -> void:
	state = {"seed": seed_value, "players": {}, "offline_players": {}, "nodes": [], "drops": [], "structures": [], "creatures": [], "discovered": [], "events": [], "clock": {"elapsed": 0.0, "day": 1, "phase": "day"}, "options": options.duplicate(true), "reset_requested": false}
	state.options.day_length = clampf(float(options.get("day_length", 480)), 30, 3600)
	GameClock.day_length = state.options.day_length
	GameClock.elapsed = 0.0
	GameClock.day = 1
	rng.seed = seed_value
	next_uid = 1
	SeedWorld.generate(self)

func add_player(peer_id: int, player_name: String) -> void:
	if state.players.has(str(peer_id)):
		return
	var player = state.offline_players.get(player_name, {})
	if player.is_empty():
		player = {"uid": -peer_id, "kind": "player", "name": player_name.left(32), "position": [0.0, 0.0, 0.0], "inventory": inventory({}).to_dict(), "stats": Stats.new().to_dict(), "ghost": false, "deaths": 0, "poison": 0.0, "mad": false}
		for key in ["attack_cd", "work_cd", "ability_cd", "sense_cd", "beast_time", "sense_time", "night_vision", "spring_heal"]:
			player[key] = 0.0
	player.uid = -peer_id
	state.offline_players.erase(player_name)
	state.players[str(peer_id)] = player

func remove_player(peer_id: int) -> void:
	var player = state.players.get(str(peer_id), {})
	if not player.is_empty():
		state.offline_players[player.name] = player
	state.players.erase(str(peer_id))

func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0 or delta > 1:
		return
	state.clock.elapsed += delta
	state.clock.day = int(state.clock.elapsed / day_length()) + 1
	GameClock.from_dict({"day_length": day_length(), "elapsed": fmod(state.clock.elapsed - delta, day_length()), "day": int((state.clock.elapsed - delta) / day_length()) + 1})
	GameClock.advance(delta)
	var fraction = fmod(state.clock.elapsed, day_length()) / day_length()
	state.clock.phase = "day" if fraction < 0.5 else ("dusk" if fraction < 0.875 else "night")
	Resources.step(self, delta)
	Structures.step(self, delta)
	Spring.step(self, delta)
	Creatures.step(self, delta)
	life.step(self, delta)
	for player in state.players.values():
		if float(player.get("recovery", 0)) > 0:
			player.recovery -= delta
			if player.recovery <= 0 and player.deaths > 0:
				player.deaths -= 1
				player.stats.max_health = 150.0 * (1 - player.deaths * 0.25)
				player.stats.revivals = player.deaths
				player.recovery = day_length() if player.deaths > 0 else 0

func action(peer_id: int, verb: String, args: Dictionary) -> bool:
	var player = state.players.get(str(peer_id), {})
	if player.is_empty() or (player.ghost and verb != "revive"):
		return false
	var accepted = false
	if verb in ["drop", "move_slot", "split", "equip", "unequip", "use", "craft"]:
		accepted = Items.perform(self, player, verb, args)
	elif verb in ["place", "fuel", "cook", "roast", "insert", "take", "chest_put", "chest_take"]:
		accepted = Structures.perform(self, player, verb, args)
	elif verb in ["water", "plant", "temper"]:
		accepted = Spring.perform(self, player, verb, args)
	elif verb == "attack":
		accepted = Combat.attack(self, player, args)
	elif verb == "ability":
		accepted = life.ability(self, player, args)
	elif verb == "revive":
		accepted = life.request_revive(self, player, args)
	elif verb in ["work", "pickup"] and player.work_cd <= 0:
		var target = find_any(args.get("uid", -1))
		if not target.is_empty() and near(player, target, 3):
			if target in state.nodes:
				accepted = Resources.work(self, player, target)
			elif verb == "pickup" and target in state.drops:
				var inv = inventory(player)
				var left = inv.add_item(target.id, target.count, target.get("extra", {}))
				accepted = left < target.count
				target.count = left
				player.inventory = inv.to_dict()
				if left == 0:
					state.drops.erase(target)
		if accepted:
			player.work_cd = 0.35
	log_event("action" if accepted else "rejected", {"peer": peer_id, "verb": verb})
	return accepted

func snapshot() -> Dictionary:
	var result = state.duplicate(true)
	result.next_uid = next_uid
	result.rng_state = str(rng.state)
	return result

func restore(data: Dictionary) -> void:
	state = data.duplicate(true)
	for player in state.players.values():
		state.offline_players[player.name] = player
	state.players = {}
	next_uid = int(state.get("next_uid", 1000))
	rng.seed = int(state.seed)
	rng.state = int(state.get("rng_state", rng.state))
	state.erase("rng_state")
	state.erase("next_uid")

func entity(kind: String, pos: Array) -> Dictionary:
	var result = {"uid": next_uid, "kind": kind, "position": pos.duplicate()}
	next_uid += 1
	return result

func drop_item(id: String, count: int, pos: Array, extra: Dictionary = {}) -> void:
	var drop = entity("drop", pos)
	drop.merge({"id": id, "count": count, "extra": Access.extra(extra)})
	state.drops.append(drop)

func inventory(player: Dictionary):
	var result = Inventory.new()
	result.from_dict(player.get("inventory", {}))
	return result

func stats(player: Dictionary):
	var result = Stats.new()
	result.from_dict(player.stats)
	return result

func find_entity(collection: Array, uid) -> Dictionary:
	if not (uid is int or uid is float):
		return {}
	for target in collection:
		if target.uid == uid:
			return target
	return {}

func find_any(uid) -> Dictionary:
	return find_entity(state.nodes + state.drops + state.structures + state.creatures, uid)

func tier(player: Dictionary) -> int:
	for structure in state.structures:
		if structure.kind == "workbench" and near(player, structure, 5):
			return 1
	return 0

func discover(id: String) -> void:
	if not state.discovered.has(id):
		state.discovered.append(id)

func log_event(event: String, details: Dictionary = {}) -> void:
	state.events.append({"event": event, "time": elapsed(), "details": details})
	if state.events.size() > 32:
		state.events.pop_front()

func item(id: String) -> Dictionary: return Access.item(id)
func recipe(id) -> Dictionary: return Access.recipe(id) if id is String else {}
func valid_slot(value) -> bool: return Items.valid_slot(value)
func valid_count(value) -> bool: return value is int and value > 0 and value <= 999
func valid_position(value) -> bool: return Access.valid_position(value)
func distance(a: Array, b: Array) -> float: return Access.distance(a, b)
func near(a: Dictionary, b: Dictionary, radius: float) -> bool: return distance(a.position, b.position) <= radius
func has_tool(player: Dictionary, tool: String) -> bool: return Access.has_tool(self, player, tool)
func wear_hand(player: Dictionary, amount: int) -> void: Access.wear_hand(player, amount)
func hurt(player: Dictionary, amount: float) -> void: Access.hurt(self, player, amount)
func day_length() -> float: return float(state.options.day_length)
func elapsed() -> float: return float(state.clock.elapsed)
func structure_kind(value: Dictionary) -> String: return str(value.get("result", "")) if value.get("is_structure", false) else ""
func craft(inv, value: Dictionary, level: int) -> bool: return inv.craft(value.resource, level)
