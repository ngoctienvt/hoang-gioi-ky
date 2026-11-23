extends RefCounted

const SKILLS_DIR := "res://data/skills/"
const IMPRINTS_DIR := "res://data/imprints/"

static var _skills: Dictionary = {}
static var _imprints: Dictionary = {}


static func _ensure_loaded() -> void:
	if _skills.is_empty():
		for file in ResourceLoader.list_directory(SKILLS_DIR):
			if file.ends_with(".tres"):
				var res = load(SKILLS_DIR + file)
				if res is SkillNodeDef and not String(res.id).is_empty():
					_skills[String(res.id)] = res
	if _imprints.is_empty():
		for file in ResourceLoader.list_directory(IMPRINTS_DIR):
			if file.ends_with(".tres"):
				var res = load(IMPRINTS_DIR + file)
				if res is ImprintDef and not String(res.id).is_empty():
					_imprints[String(res.id)] = res


static func get_skill(skill_id: String) -> SkillNodeDef:
	_ensure_loaded()
	return _skills.get(skill_id, null)


static func skills_for_tree(tree_id: String) -> Array:
	_ensure_loaded()
	var out: Array = []
	for s in _skills.values():
		if String(s.tree_id) == tree_id:
			out.append(s)
	out.sort_custom(func(a, b):
		if int(a.tier) != int(b.tier):
			return int(a.tier) < int(b.tier)
		return String(a.branch) < String(b.branch)
	)
	return out


static func all_imprints() -> Array:
	_ensure_loaded()
	var out: Array = _imprints.values()
	out.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return out


static func imprint_for_item(item_id: String) -> ImprintDef:
	_ensure_loaded()
	for imp in _imprints.values():
		if String(imp.item_id) == item_id:
			return imp
	return null


static func has_skill(player: Dictionary, skill_id: String) -> bool:
	return skill_id in player.get("skills", [])


static func has_imprint_effect(player: Dictionary, effect_id: String) -> bool:
	_ensure_loaded()
	for imp_id in player.get("imprints", []):
		var imp: ImprintDef = _imprints.get(str(imp_id), null)
		if imp != null and String(imp.effect_id) == effect_id:
			return true
	return false


static func unlock_skill(world, player: Dictionary, args: Dictionary) -> bool:
	var sid := str(args.get("skill_id", ""))
	var sdef := get_skill(sid)
	if sdef == null:
		return false
	var cdef = world.Abilities.character_def(player)
	if cdef == null or String(cdef.skill_tree_id) != String(sdef.tree_id):
		return false
	if int(player.get("skill_points", 0)) < 1:
		return false
	if int(player.get("awakening_tier", 0)) < int(sdef.tier):
		return false
	var unlocked: Array = player.get("skills", [])
	if sid in unlocked:
		return false
	for ex in sdef.excludes:
		if String(ex) in unlocked:
			return false
	unlocked.append(sid)
	player["skills"] = unlocked
	player["skill_points"] = int(player.get("skill_points", 0)) - 1
	if String(sdef.effect_id) == "poison_threshold_up":
		player["poison_threshold"] = float(player.get("poison_threshold", 150.0)) + 30.0
	world.log_event("skill_unlocked", {"name": player.name, "skill": sid})
	return true


static func equip_imprint(world, player: Dictionary, args: Dictionary) -> bool:
	var idx = args.get("slot", -1)
	if not world.valid_slot(idx):
		return false
	var inv = world.inventory(player)
	var slot: Dictionary = inv.slots[idx]
	if slot.is_empty():
		return false
	var imp := imprint_for_item(str(slot.id))
	if imp == null:
		return false
	var max_slots := mini(3, int(player.get("awakening_tier", 0)))
	var imprints: Array = player.get("imprints", [])
	if imprints.size() >= max_slots or String(imp.id) in imprints:
		return false
	inv.slots[idx].count -= 1
	if inv.slots[idx].count <= 0:
		inv.slots[idx] = {}
	player.inventory = inv.to_dict()
	imprints.append(String(imp.id))
	player["imprints"] = imprints
	world.log_event("imprint_equipped", {"name": player.name, "imprint": String(imp.id)})
	return true


static func unequip_imprint(world, player: Dictionary, args: Dictionary) -> bool:
	var idx := int(args.get("index", -1))
	var imprints: Array = player.get("imprints", [])
	if idx < 0 or idx >= imprints.size():
		return false
	var imp_id := str(imprints[idx])
	_ensure_loaded()
	var imp: ImprintDef = _imprints.get(imp_id, null)
	var item_id := String(imp.item_id) if imp != null else imp_id
	var inv = world.inventory(player)
	if inv.add_item(item_id, 1) != 0:
		return false
	imprints.remove_at(idx)
	player["imprints"] = imprints
	player.inventory = inv.to_dict()
	return true
