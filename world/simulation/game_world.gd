class_name GameWorld
extends RefCounted

const Inventory = preload("res://components/inventory_component.gd")
const Stats = preload("res://components/survival_stats.gd")
const Rules = preload("res://world/simulation/world_rules.gd")
const EntityIndex = preload("res://world/simulation/world_entity_index.gd")
const SeedWorld = preload("res://world/simulation/world_seed.gd")
const Resources = preload("res://world/simulation/world_resources.gd")
const Structures = preload("res://world/simulation/world_structures.gd")
const Items = preload("res://world/simulation/world_inventory.gd")
const Spring = preload("res://world/simulation/world_spring.gd")
const Combat = preload("res://world/simulation/world_combat.gd")
const Creatures = preload("res://world/simulation/world_creatures.gd")
const Access = preload("res://world/simulation/world_access.gd")
const Layout = preload("res://world/simulation/world_layout.gd")
const Teleport = preload("res://world/simulation/world_teleport.gd")
const Season = preload("res://world/simulation/world_season.gd")
const Weather = preload("res://world/simulation/world_weather.gd")
const Spoilage = preload("res://world/simulation/world_spoilage.gd")
const Effects = preload("res://world/simulation/world_effects.gd")
const Farming = preload("res://world/simulation/world_farming.gd")
const HeartDemon = preload("res://world/simulation/world_heart_demon.gd")
const Tempering = preload("res://world/simulation/world_tempering.gd")
const Puppets = preload("res://world/simulation/world_puppets.gd")
const Stations = preload("res://world/simulation/world_stations.gd")
const Talismans = preload("res://world/simulation/world_talismans.gd")
const Karma = preload("res://world/simulation/world_karma.gd")
const Npcs = preload("res://world/simulation/world_npcs.gd")
const Abilities = preload("res://world/simulation/world_abilities.gd")
const Skills = preload("res://world/simulation/world_skills.gd")
const Awakening = preload("res://world/simulation/world_awakening.gd")
const Bosses = preload("res://world/simulation/world_bosses.gd")
const SecretRealm = preload("res://world/simulation/world_secret_realm.gd")
var life = preload("res://world/simulation/world_life.gd")

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var next_uid := 1
var index := EntityIndex.new()
var regrowing_uids: Dictionary = {}
var active_traps: Dictionary = {}


func initialize(seed_value: int, options: Dictionary) -> void:
	state = {
		"seed": seed_value,
		"players": {},
		"offline_players": {},
		"nodes": [],
		"drops": [],
		"structures": [],
		"creatures": [],
		"puppets": [],
		"npcs": [],
		"regions": [],
		"teleports": [],
		"discovered": [],
		"forbidden_recipes": [],
		"karma": {"sin": 0.0, "fate": 0.0},
		"karma_history": [],
		"karma_cooldowns": {},
		"rituals": [],
		"secret_realm": {"built": false, "switches_active": 0, "unlocked": false},
		"events": [],
		"clock": {"elapsed": 0.0, "day": 1, "phase": "day", "season": "autumn", "season_day": 1, "days_to_next_season": 20, "season_warning": false, "day_segments": 8, "dusk_segments": 6, "night_segments": 2},
		"weather": {"kind": "clear", "timer": 0.0, "lightning_cd": 0.0, "fire_cd": 0.0, "warnings": []},
		"options": options.duplicate(true),
		"reset_requested": false,
	}
	state.options.day_length = clampf(float(options.get("day_length", 480)), 30, 3600)
	state.options.map_size = clampf(float(options.get("map_size", Layout.DEFAULT_MAP_SIZE)), 48.0, 2048.0)
	if not state.options.has("seasons"):
		state.options["seasons"] = true
	if not state.options.has("season_lengths") or not state.options.season_lengths is Dictionary:
		state.options["season_lengths"] = {"autumn": 20, "winter": 15, "spring": 20, "summer": 15}
	GameClock.day_length = state.options.day_length
	GameClock.elapsed = 0.0
	GameClock.day = 1
	Season.update_clock(self)
	rng.seed = seed_value
	next_uid = 1
	index.clear()
	regrowing_uids.clear()
	active_traps.clear()
	SeedWorld.generate(self)


func map_size() -> float:
	return float(state.get("options", {}).get("map_size", Layout.DEFAULT_MAP_SIZE))


func biome_at(pos: Array) -> String:
	return Layout.biome_at(state.get("regions", []), pos)


func map_half() -> float:
	return map_size() * 0.5


func add_entity(collection: String, entity_data: Dictionary) -> Dictionary:
	state[collection].append(entity_data)
	index.add(collection, entity_data)
	if collection == "nodes" and (float(entity_data.get("regrow", 0.0)) > 0.0 or entity_data.get("sapling", false)):
		regrowing_uids[int(entity_data.uid)] = true
	return entity_data


func remove_entity(entity_data: Dictionary) -> void:
	if entity_data.is_empty():
		return
	var uid := int(entity_data.get("uid", 0))
	var col: String = index.collection_of.get(uid, "")
	if not col.is_empty():
		state[col].erase(entity_data)
	else:
		for c in ["nodes", "drops", "structures", "creatures", "puppets", "npcs"]:
			if entity_data in state.get(c, []):
				state[c].erase(entity_data)
				break
	regrowing_uids.erase(uid)
	active_traps.erase(uid)
	index.remove(uid)


func clear_entities() -> void:
	for c in ["nodes", "drops", "structures", "creatures", "puppets", "npcs"]:
		if state.has(c):
			state[c].clear()
	regrowing_uids.clear()
	active_traps.clear()
	index.clear()


func rebuild_index() -> void:
	index.rebuild(state)
	regrowing_uids.clear()
	active_traps.clear()
	for node in state.get("nodes", []):
		if float(node.get("regrow", 0.0)) > 0.0 or node.get("sapling", false):
			regrowing_uids[int(node.uid)] = true
		if node.get("kind", "") == "floor_trap" and float(node.get("cooldown", 0.0)) > 0.0:
			active_traps[int(node.uid)] = true


func touch(uid: int) -> void:
	index.touch(uid)


func set_field(entity_data: Dictionary, key: String, value) -> void:
	entity_data[key] = value
	touch(int(entity_data.get("uid", 0)))


func move_entity(entity_data: Dictionary, new_pos: Array, reliable: bool = false) -> void:
	entity_data.position = new_pos
	index.update_position(entity_data)
	var uid := int(entity_data.get("uid", 0))
	if reliable:
		index.touch(uid)
	else:
		index.mark_creature_moved(uid)


func add_player(peer_id: int, player_name: String) -> void:
	if state.players.has(str(peer_id)):
		return
	var player: Dictionary = state.offline_players.get(player_name, {})
	if player.is_empty():
		player = {
			"uid": -peer_id,
			"kind": "player",
			"name": player_name.left(32),
			"position": [0.0, 0.0, 0.0],
			"inventory": inventory({}).to_dict(),
			"stats": Stats.new().to_dict(),
			"ghost": false,
			"deaths": 0,
			"poison": 0.0,
			"mad": false,
			"biome": "bamboo_forest",
			"in_mud": false,
			"effects": {},
			"poison_threshold": 50.0,
			"character": "",
			"ability_cds": {},
			"rage": 0.0,
			"devour_history": [],
			"awakening_tier": 0,
			"skill_points": 0,
			"skills": [],
			"imprints": [],
			"in_secret_realm": false,
		}
		for key in Rules.PLAYER_TIMERS:
			player[key] = 0.0
	else:
		for key in Rules.PLAYER_TIMERS:
			if not player.has(key):
				player[key] = 0.0
		if not player.has("effects") or not player.effects is Dictionary:
			player["effects"] = {}
		if not player.has("poison_threshold"):
			player["poison_threshold"] = 50.0
		if not player.has("character"):
			player["character"] = ""
		if not player.has("ability_cds") or not player.ability_cds is Dictionary:
			player["ability_cds"] = {}
		if not player.has("rage"):
			player["rage"] = 0.0
		if not player.has("devour_history") or not player.devour_history is Array:
			player["devour_history"] = []
		if not player.has("awakening_tier"):
			player["awakening_tier"] = 0
		if not player.has("skill_points"):
			player["skill_points"] = 0
		if not player.has("skills") or not player.skills is Array:
			player["skills"] = []
		if not player.has("imprints") or not player.imprints is Array:
			player["imprints"] = []
		if player.get("inventory", {}).get("slots", []).size() < Inventory.SLOT_COUNT:
			player.inventory = inventory(player).to_dict()
	player.uid = -peer_id
	player.biome = biome_at(player.get("position", [0.0, 0.0, 0.0]))
	state.offline_players.erase(player_name)
	state.players[str(peer_id)] = player


func remove_player(peer_id: int) -> void:
	var player: Dictionary = state.players.get(str(peer_id), {})
	if not player.is_empty():
		state.offline_players[player.name] = player
	state.players.erase(str(peer_id))


func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0 or delta > 1:
		return
	var prev_day := int(state.clock.get("day", 1))
	state.clock.elapsed += delta
	Season.update_clock(self)
	if int(state.clock.get("day", 1)) != prev_day:
		Karma.on_new_day(self)
	GameClock.from_dict({
		"day_length": day_length(),
		"elapsed": fmod(maxf(0.0, state.clock.elapsed - delta), day_length()),
		"day": int(maxf(0.0, state.clock.elapsed - delta) / day_length()) + 1,
		"season": state.clock.get("season", "autumn"),
		"season_day": state.clock.get("season_day", 1),
		"days_to_next_season": state.clock.get("days_to_next_season", 20),
		"day_segments": state.clock.get("day_segments", 8),
		"dusk_segments": state.clock.get("dusk_segments", 6),
		"night_segments": state.clock.get("night_segments", 2),
	})
	GameClock.advance(delta)
	Resources.step(self, delta)
	Structures.step(self, delta)
	Spring.step(self, delta)
	Teleport.step(self, delta)
	Weather.step(self, delta)
	Spoilage.step(self, delta)
	Creatures.step(self, delta)
	Puppets.step(self, delta)
	Awakening.step(self, delta)
	SecretRealm.step(self, delta)
	HeartDemon.step(self, delta)
	Npcs.step(self, delta)
	life.step(self, delta)
	for player in state.players.values():
		if float(player.get("recovery", 0)) > 0:
			player.recovery -= delta
			if player.recovery <= 0 and player.deaths > 0:
				player.deaths -= 1
				var base_hp := float(player.stats.get("base_max_health", Rules.BASE_MAX_HEALTH))
				player.stats.max_health = base_hp * (1.0 - player.deaths * 0.25)
				player.stats.revivals = player.deaths
				player.recovery = day_length() if player.deaths > 0 else 0


func action(peer_id: int, verb: String, args: Dictionary) -> bool:
	var player: Dictionary = state.players.get(str(peer_id), {})
	if player.is_empty() or (player.ghost and verb != "revive"):
		return false
	var accepted := false
	if verb in ["drop", "move_slot", "split", "equip", "unequip", "use", "craft"]:
		accepted = Items.perform(self, player, verb, args)
	elif verb in ["place", "fuel", "cook", "roast", "insert", "take", "chest_put", "chest_take"]:
		accepted = Structures.perform(self, player, verb, args)
	elif verb in ["water", "plant", "temper"]:
		accepted = Spring.perform(self, player, verb, args)
	elif verb == "throw_talisman":
		accepted = Talismans.throw_talisman(self, player, args)
	elif verb == "trade":
		accepted = Npcs.trade(self, player, args)
	elif verb == "fulfill_request":
		accepted = Npcs.fulfill_request(self, player, args)
	elif verb == "invite_guest":
		accepted = Npcs.invite_guest(self, player, args)
	elif verb == "offer_altar":
		accepted = Karma.offer_altar(self, player, args)
	elif verb == "capture_beast":
		accepted = Karma.capture_beast(self, player, args)
	elif verb == "release_beast":
		accepted = Karma.release_beast(self, player, args)
	elif verb == "teleport":
		accepted = Teleport.perform(self, player, args)
	elif verb == "attack":
		accepted = Combat.attack(self, player, args)
	elif verb == "choose_character":
		accepted = Abilities.choose_character(self, player, args)
	elif verb == "ability":
		accepted = Abilities.ability(self, player, args)
	elif verb == "start_awakening":
		accepted = Awakening.start_ritual(self, player, args)
	elif verb == "unlock_skill":
		accepted = Skills.unlock_skill(self, player, args)
	elif verb == "equip_imprint":
		accepted = Skills.equip_imprint(self, player, args)
	elif verb == "unequip_imprint":
		accepted = Skills.unequip_imprint(self, player, args)
	elif verb == "summon_boss":
		accepted = Bosses.summon_boss(self, player, args)
	elif verb == "enter_secret_realm":
		accepted = SecretRealm.enter_realm(self, player, args)
	elif verb == "exit_secret_realm":
		accepted = SecretRealm.exit_realm(self, player, args)
	elif verb == "activate_switch":
		accepted = SecretRealm.activate_switch(self, player, args)
	elif verb == "claim_vault":
		accepted = SecretRealm.claim_vault(self, player, args)
	elif verb == "revive":
		accepted = life.request_revive(self, player, args)
	elif verb in ["work", "pickup"] and player.work_cd <= 0:
		var target := find_any(args.get("uid", -1))
		if not target.is_empty() and near(player, target, 3):
			var col: String = index.collection_of.get(int(target.uid), "")
			if col == "nodes":
				accepted = Resources.work(self, player, target, bool(args.get("auto_equip", false)))
			elif verb == "pickup" and col == "drops":
				var inv = inventory(player)
				var left: int = inv.add_item(target.id, target.count, target.get("extra", {}))
				accepted = left < target.count
				target.count = left
				player.inventory = inv.to_dict()
				if left == 0:
					remove_entity(target)
				elif accepted:
					touch(int(target.uid))
		if accepted:
			player.work_cd = 0.35
	return accepted


func snapshot() -> Dictionary:
	var result := state.duplicate(true)
	result.next_uid = next_uid
	result.rng_state = str(rng.state)
	return result


## Loads a snapshot. Older saves must go through SaveManager's migration first; defaults for missing
## fields live there only.
func restore(data: Dictionary) -> void:
	state = data.duplicate(true)
	for player in state.players.values():
		state.offline_players[player.name] = player
	state.players = {}
	for offline_name in state.offline_players:
		var offline_player = state.offline_players[offline_name]
		if offline_player is Dictionary:
			offline_player.inventory = inventory(offline_player).to_dict()
	for s in state.get("structures", []):
		if s is Dictionary and s.get("slots") is Array:
			var old_size: int = s.slots.size()
			if old_size < Inventory.SLOT_COUNT:
				s.slots.resize(Inventory.SLOT_COUNT)
				for idx in range(old_size, Inventory.SLOT_COUNT):
					s.slots[idx] = {}
	Karma.ensure_state(self)
	Season.update_clock(self)
	next_uid = int(state.get("next_uid", 1000))
	rng.seed = int(state.seed)
	rng.state = int(state.get("rng_state", rng.state))
	state.erase("rng_state")
	state.erase("next_uid")
	rebuild_index()


func entity(kind: String, pos: Array) -> Dictionary:
	var result := {"uid": next_uid, "kind": kind, "position": pos.duplicate()}
	next_uid += 1
	return result


func drop_item(id: String, count: int, pos: Array, extra: Dictionary = {}) -> void:
	var drop := entity("drop", pos)
	drop.merge({"id": id, "count": count, "extra": Access.extra(extra)})
	add_entity("drops", drop)


func inventory(player: Dictionary):
	var result := Inventory.new()
	result.from_dict(player.get("inventory", {}))
	return result


func stats(player: Dictionary):
	var result := Stats.new()
	result.from_dict(player.stats)
	result.poison_threshold = float(player.get("poison_threshold", 50.0))
	result.poison_backlash_mult = 2.0 if str(player.get("character", "")) == "devourer" else 1.0
	return result


func find_any(uid) -> Dictionary:
	return index.find(uid)


func tier(player: Dictionary) -> int:
	for structure in index.entities_near(player.position, 5.0, "structures"):
		if structure.kind == "workbench":
			return 1
	return 0


func discover(id: String) -> void:
	if not state.discovered.has(id):
		state.discovered.append(id)


## Host-side log of notable world events (kept in saves, not replicated).
func log_event(event: String, details: Dictionary = {}) -> void:
	state.events.append({"event": event, "time": elapsed(), "details": details})
	if state.events.size() > 32:
		state.events.pop_front()


func item(id: String) -> Dictionary: return Access.item(id)
func recipe(id) -> Dictionary: return Access.recipe(id) if id is String else {}
func valid_slot(value) -> bool: return Items.valid_slot(value)
func valid_count(value) -> bool: return value is int and value > 0 and value <= 999
func valid_position(value) -> bool: return Access.valid_position(value, map_half())
func distance(a: Array, b: Array) -> float: return Access.distance(a, b)
func near(a: Dictionary, b: Dictionary, radius: float) -> bool: return distance(a.position, b.position) <= radius
func has_tool(player: Dictionary, tool: String, min_tier: int = 1) -> bool: return Access.has_tool(self, player, tool, min_tier)
func wear_hand(player: Dictionary, amount: int) -> void: Access.wear_hand(player, amount)
func hurt(player: Dictionary, amount: float) -> void: Access.hurt(self, player, amount)
func day_length() -> float: return float(state.options.day_length)
func elapsed() -> float: return float(state.clock.elapsed)
func structure_kind(value: Dictionary) -> String: return str(value.get("result", "")) if value.get("is_structure", false) else ""
func craft(inv, value: Dictionary, level: int, ingredient_override: Dictionary = {}) -> bool: return inv.craft(value.resource, level, ingredient_override)
