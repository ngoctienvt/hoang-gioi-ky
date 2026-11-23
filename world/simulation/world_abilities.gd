extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

const CHAR_DIR := "res://data/characters/"
const BeastRage = preload("res://world/simulation/traits/beast_rage.gd")
const DevourerConflict = preload("res://world/simulation/traits/devourer_conflict.gd")

const ABILITY_SCRIPTS := {
	"beast": preload("res://world/simulation/abilities/beast.gd"),
	"sense": preload("res://world/simulation/abilities/sense.gd"),
	"devour": preload("res://world/simulation/abilities/devour.gd"),
	"summon_puppet": preload("res://world/simulation/abilities/summon_puppet.gd"),
	"command_puppet": preload("res://world/simulation/abilities/command_puppet.gd"),
	"shadow_step": preload("res://world/simulation/abilities/shadow_step.gd"),
	"yin_yang_palm": preload("res://world/simulation/abilities/yin_yang_palm.gd"),
}

static var _characters: Dictionary = {}


static func _ensure_loaded() -> void:
	if not _characters.is_empty():
		return
	for file in ResourceLoader.list_directory(CHAR_DIR):
		if file.ends_with(".tres"):
			var res = load(CHAR_DIR + file)
			if res is CharacterDef and not String(res.id).is_empty():
				_characters[String(res.id)] = res


static func all_characters() -> Array:
	_ensure_loaded()
	var list: Array = _characters.values()
	list.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return list


static func selectable_characters() -> Array:
	var out: Array = []
	for c in all_characters():
		if c.selectable:
			out.append(c)
	return out


static func get_character(id: String) -> CharacterDef:
	_ensure_loaded()
	return _characters.get(id, _characters.get("beast_bloodline", null))


static func effective_character_id(player: Dictionary) -> String:
	var cid := str(player.get("character", ""))
	return "beast_bloodline" if cid.is_empty() else cid


static func character_def(player: Dictionary) -> CharacterDef:
	return get_character(effective_character_id(player))


static func choose_character(world, player: Dictionary, args: Dictionary) -> bool:
	if not str(player.get("character", "")).is_empty():
		return false
	var cid := str(args.get("character", ""))
	_ensure_loaded()
	var cdef: CharacterDef = _characters.get(cid, null)
	if cdef == null or not cdef.selectable:
		return false
	player["character"] = String(cdef.id)
	var revivals := clampi(int(player.get("deaths", 0)), 0, 2)
	var max_hp := cdef.max_health * (1.0 - 0.25 * revivals)
	player.stats["base_max_health"] = cdef.max_health
	player.stats["max_health"] = max_hp
	if float(player.stats.get("health", Rules.BASE_MAX_HEALTH)) >= Rules.BASE_MAX_HEALTH:
		player.stats["health"] = max_hp
	else:
		player.stats["health"] = minf(max_hp, float(player.stats.get("health", max_hp)))
	player["poison_threshold"] = cdef.poison_threshold
	if cid == "yin_yang":
		player.stats["dao"] = 50.0
	if not player.has("ability_cds") or not player.ability_cds is Dictionary:
		player["ability_cds"] = {}
	player["rage"] = 0.0
	player["devour_history"] = []
	world.log_event("choose_character", {"name": player.name, "character": cid})
	return true


static func ability(world, player: Dictionary, args: Dictionary) -> bool:
	var ab_name := str(args.get("name", ""))
	var cdef := character_def(player)
	if cdef == null:
		return false
	var adef: AbilityDef = null
	for entry in cdef.abilities:
		if entry != null and String(entry.id) == ab_name:
			adef = entry
			break
	if adef == null:
		return false
	var cds: Dictionary = player.get("ability_cds", {})
	if float(cds.get(ab_name, 0.0)) > 0.0:
		return false
	if ab_name == "beast" and float(player.get("ability_cd", 0.0)) > 0.0:
		return false
	if ab_name == "sense" and float(player.get("sense_cd", 0.0)) > 0.0:
		return false
	if not _can_pay_cost(world, player, adef):
		return false
	var handler = ABILITY_SCRIPTS.get(ab_name, null)
	if handler == null or not handler.execute(world, player, args, adef):
		return false
	_pay_cost(world, player, adef)
	if adef.forbidden:
		world.Karma.add_sin(world, adef.sin_amount)
	if not player.has("ability_cds") or not player.ability_cds is Dictionary:
		player["ability_cds"] = {}
	var cd_val := float(adef.cooldown)
	if world.Skills.has_skill(player, "puppet_t3_swift_cast"):
		cd_val *= 0.5
	elif world.Skills.has_skill(player, "devour_t3_soul_feast") and ab_name == "devour":
		cd_val *= 0.25
	player.ability_cds[ab_name] = cd_val
	if ab_name == "beast":
		player["ability_cd"] = cd_val
	elif ab_name == "sense":
		player["sense_cd"] = cd_val
	return true


static func _can_pay_cost(world, player: Dictionary, adef: AbilityDef) -> bool:
	var stats: Dictionary = player.get("stats", {})
	match adef.cost_type:
		"stamina":
			return float(stats.get("stamina", 0.0)) >= adef.cost_amount
		"dao":
			return float(stats.get("dao", 0.0)) >= adef.cost_amount
		"health":
			return float(stats.get("health", 0.0)) > adef.cost_amount
		"item":
			var inv = world.inventory(player)
			return inv.count_item(String(adef.cost_item)) >= int(adef.cost_amount)
		_:
			return true


static func _pay_cost(world, player: Dictionary, adef: AbilityDef) -> void:
	var stats: Dictionary = player.get("stats", {})
	match adef.cost_type:
		"stamina":
			stats["stamina"] = maxf(0.0, float(stats.get("stamina", 0.0)) - adef.cost_amount)
		"dao":
			stats["dao"] = maxf(0.0, float(stats.get("dao", 0.0)) - adef.cost_amount)
		"health":
			stats["health"] = maxf(1.0, float(stats.get("health", 1.0)) - adef.cost_amount)
		"item":
			var inv = world.inventory(player)
			inv.remove_item(String(adef.cost_item), int(adef.cost_amount))
			player.inventory = inv.to_dict()


static func step_player(world, player: Dictionary, stats, delta: float, modifiers: Dictionary) -> void:
	var cds = player.get("ability_cds", {})
	if cds is Dictionary:
		for key in cds.keys():
			cds[key] = maxf(0.0, float(cds[key]) - delta)
	var cid := effective_character_id(player)
	if cid == "beast_bloodline":
		BeastRage.step(world, player, stats, delta, modifiers)
	elif cid == "devourer":
		DevourerConflict.step(world, player, stats, delta, modifiers)
