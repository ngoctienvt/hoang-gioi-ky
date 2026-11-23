extends RefCounted

const Events = preload("res://world/simulation/world_karma_events.gd")
const RULES_PATH := "res://data/karma/karma_rules.tres"
const EVENTS_DIR := "res://data/karma/"

static var _cached_rules: KarmaRulesDef = null
static var _cached_events: Array = []


static func rules() -> KarmaRulesDef:
	if _cached_rules == null and ResourceLoader.exists(RULES_PATH):
		_cached_rules = load(RULES_PATH) as KarmaRulesDef
	if _cached_rules == null:
		_cached_rules = KarmaRulesDef.new()
	return _cached_rules


static func all_events() -> Array:
	if not _cached_events.is_empty():
		return _cached_events
	for file in ResourceLoader.list_directory(EVENTS_DIR):
		if file.ends_with(".tres") and file != "karma_rules.tres":
			var ev = load(EVENTS_DIR + file)
			if ev is KarmaEventDef:
				_cached_events.append(ev)
	_cached_events.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return _cached_events


static func ensure_state(world) -> Dictionary:
	if not world.state.has("karma") or not world.state.karma is Dictionary:
		world.state["karma"] = {"sin": 0.0, "fate": 0.0}
	if not world.state.has("karma_history") or not world.state.karma_history is Array:
		world.state["karma_history"] = []
	if not world.state.has("karma_cooldowns") or not world.state.karma_cooldowns is Dictionary:
		world.state["karma_cooldowns"] = {}
	if not world.state.has("forbidden_recipes") or not world.state.forbidden_recipes is Array:
		world.state["forbidden_recipes"] = []
	return world.state.karma


static func add_sin(world, action_or_amount) -> void:
	var k := ensure_state(world)
	var amt := float(action_or_amount) if (action_or_amount is int or action_or_amount is float) else float(rules().get(str(action_or_amount)) if rules().get(str(action_or_amount)) != null else 0.0)
	if amt <= 0.0:
		return
	k.sin = clampf(float(k.get("sin", 0.0)) + amt, 0.0, 120.0)
	check_thresholds(world)


static func add_fate(world, action_or_amount) -> void:
	var k := ensure_state(world)
	var amt := float(action_or_amount) if (action_or_amount is int or action_or_amount is float) else float(rules().get(str(action_or_amount)) if rules().get(str(action_or_amount)) != null else 0.0)
	if amt <= 0.0:
		return
	k.fate = clampf(float(k.get("fate", 0.0)) + amt, 0.0, 120.0)
	check_thresholds(world)


static func on_new_day(world) -> void:
	var k := ensure_state(world)
	var decay := float(rules().daily_decay)
	k.sin = maxf(0.0, float(k.get("sin", 0.0)) - decay)
	k.fate = maxf(0.0, float(k.get("fate", 0.0)) - decay)
	check_thresholds(world)


static func check_thresholds(world) -> Array:
	var triggered: Array = []
	if not bool(world.state.get("options", {}).get("karma", true)):
		return triggered
	var k := ensure_state(world)
	var day := int(world.state.get("clock", {}).get("day", 1))
	var cds: Dictionary = world.state.karma_cooldowns
	var sin_v := float(k.get("sin", 0.0))
	var fate_v := float(k.get("fate", 0.0))
	if sin_v >= 60.0 and fate_v >= 60.0 and _ready_slot(cds, "both_60", day):
		var ev := _pick_event(world, "both", 60)
		if ev != null:
			# Both bars high: one draw from the hybrid pool replaces the per-bar events.
			_fire_event(world, ev, "both_60", day)
			triggered.append(String(ev.id))
			return triggered
	for bar in ["sin", "fate"]:
		var val := float(k.get(bar, 0.0))
		for th in [100, 60, 30]:
			var slot_key := "%s_%d" % [bar, th]
			if val < float(th):
				cds.erase(slot_key)
				continue
			# Only the highest tier reached may fire; a tier on cooldown does not fall through.
			if _ready_slot(cds, slot_key, day):
				var ev := _pick_event(world, bar, th)
				if ev != null:
					_fire_event(world, ev, slot_key, day)
					triggered.append(String(ev.id))
			break
	return triggered


static func _ready_slot(cds: Dictionary, key: String, day: int) -> bool:
	if not cds.has(key):
		return true
	return day - int(cds[key]) >= 3


static func _pick_event(world, bar: String, threshold: int) -> KarmaEventDef:
	var pool: Array = []
	var total := 0.0
	for ev in all_events():
		if ev.bar == bar and int(ev.threshold) == threshold:
			pool.append(ev)
			total += maxf(0.01, float(ev.weight))
	if pool.is_empty():
		return null
	var cursor: float = world.rng.randf() * total
	for ev in pool:
		cursor -= maxf(0.01, float(ev.weight))
		if cursor <= 0.0:
			return ev
	return pool.back()


static func _fire_event(world, ev: KarmaEventDef, slot_key: String, day: int) -> void:
	var k := ensure_state(world)
	var cost := float(ev.cost)
	if ev.bar == "both":
		k.sin = maxf(0.0, float(k.sin) - cost)
		k.fate = maxf(0.0, float(k.fate) - cost)
	elif ev.bar == "sin":
		k.sin = maxf(0.0, float(k.sin) - cost)
	else:
		k.fate = maxf(0.0, float(k.fate) - cost)
	world.state.karma_cooldowns[slot_key] = day
	world.state.karma_history.append({"id": String(ev.id), "day": day, "bar": ev.bar, "threshold": ev.threshold})
	if world.state.karma_history.size() > 16:
		world.state.karma_history.pop_front()
	Events.execute(world, ev)
	world.log_event("karma_event", {"id": String(ev.id), "bar": ev.bar})


static func offer_altar(world, player: Dictionary, args: Dictionary) -> bool:
	var altar: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if altar.is_empty() or altar.kind != "altar" or not world.near(player, altar, 3.5):
		return false
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if not world.valid_slot(index) or inv.slots[index].is_empty():
		return false
	var item_def := ItemDB.get_item(str(inv.slots[index].id))
	if item_def == null or item_def.get_tag(&"spirit") <= 0.0:
		return false
	inv.slots[index].count -= 1
	if inv.slots[index].count <= 0:
		inv.slots[index] = {}
	player.inventory = inv.to_dict()
	add_fate(world, "altar_offering")
	return true


static func capture_beast(world, player: Dictionary, args: Dictionary) -> bool:
	var target: Dictionary = world.index.find_in("creatures", args.get("uid", -1))
	if target.is_empty() or target.kind not in ["rabbit", "spirit_rabbit", "pheasant"] or float(target.get("health", 0.0)) <= 0.0 or not world.near(player, target, 3.5):
		return false
	var inv = world.inventory(player)
	if not inv.remove_item("beast_cage", 1):
		return false
	if inv.add_item("filled_beast_cage", 1, {"creature": target.kind}) != 0:
		inv.add_item("beast_cage", 1)
		return false
	player.inventory = inv.to_dict()
	world.remove_entity(target)
	return true


static func release_beast(world, player: Dictionary, args: Dictionary) -> bool:
	var inv = world.inventory(player)
	var index = args.get("slot", -1)
	if not world.valid_slot(index) or inv.slots[index].is_empty() or inv.slots[index].id != "filled_beast_cage":
		return false
	var kind := str(inv.slots[index].get("creature", "rabbit"))
	inv.slots[index].count -= 1
	if inv.slots[index].count <= 0:
		inv.slots[index] = {}
	inv.add_item("beast_cage", 1)
	player.inventory = inv.to_dict()
	var c: Dictionary = world.entity(kind, [float(player.position[0]) + 1.5, 0.0, float(player.position[2])])
	c.merge({"health": 25.0, "max_health": 25.0, "state": "flee", "home": player.position.duplicate(), "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "no_respawn": true})
	world.add_entity("creatures", c)
	add_fate(world, "release_beast")
	return true
