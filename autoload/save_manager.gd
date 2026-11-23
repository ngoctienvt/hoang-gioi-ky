extends Node

const SAVE_DIR := "user://saves/"
const MAX_SAVE_BYTES := 16000000
const SAVE_VERSION := 10


func _valid_slot(slot: String) -> bool:
	if slot.is_empty() or slot.length() > 64:
		return false
	for character in slot:
		if not character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	return true


func save_world(state: Dictionary, slot: String = "world") -> Error:
	if not multiplayer.is_server():
		return ERR_UNAUTHORIZED
	if not _valid_slot(slot):
		push_warning("[SaveManager] Invalid slot name")
		return ERR_INVALID_PARAMETER
	var text := JSON.stringify({"version": SAVE_VERSION, "state": JSON.from_native(state)})
	if text.length() > MAX_SAVE_BYTES:
		return ERR_OUT_OF_MEMORY
	var result := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if result != OK:
		return result
	var path := SAVE_DIR + slot + ".json"
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot write save")
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak")
	result = DirAccess.rename_absolute(tmp_path, path)
	if result != OK:
		push_error("[SaveManager] Cannot replace save: %d" % result)
	return result


func load_world(slot: String = "world") -> Dictionary:
	if not _valid_slot(slot):
		return {}
	var base := SAVE_DIR + slot + ".json"
	for path in [base, base + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > MAX_SAVE_BYTES:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			var migrated := migrate_envelope(parsed)
			if not migrated.is_empty():
				return migrated
	return {}


func migrate_envelope(parsed: Dictionary) -> Dictionary:
	if not parsed.has("version"):
		push_warning("[SaveManager] Missing save version")
		return {}
	var version := int(parsed.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		push_warning("[SaveManager] Unsupported save version: %d" % version)
		return {}
	var raw_state = parsed.get("state")
	var state = JSON.to_native(raw_state) if (raw_state is Dictionary and raw_state.has("type")) else raw_state
	if not state is Dictionary:
		push_warning("[SaveManager] Invalid save state payload")
		return {}
	return _migrate(state, version)


func _migrate(state: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	var data := state.duplicate(true)
	while v < SAVE_VERSION:
		if v == 1:
			if not data.has("options") or not data.options is Dictionary:
				data["options"] = {}
			if not data.options.has("map_size"):
				data.options["map_size"] = 80.0
		elif v == 2:
			if not data.has("regions") or not data.regions is Array or data.regions.is_empty():
				data["regions"] = _default_regions(int(data.get("seed", 12345)), float(data.get("options", {}).get("map_size", 80.0)))
			if not data.has("teleports") or not data.teleports is Array:
				data["teleports"] = []
			for node in data.get("nodes", []):
				if node is Dictionary and str(node.get("kind", "")) == "spring" and not node.has("water_type"):
					node["water_type"] = "thanh_moc"
		elif v == 3:
			if not data.has("clock") or not data.clock is Dictionary:
				data["clock"] = {}
			if not data.clock.has("season"):
				data.clock["season"] = "autumn"
			if not data.clock.has("season_day"):
				data.clock["season_day"] = 1
			if not data.clock.has("days_to_next_season"):
				data.clock["days_to_next_season"] = 20
			if not data.has("weather") or not data.weather is Dictionary:
				data["weather"] = {"kind": "clear", "timer": 0.0, "lightning_cd": 0.0, "fire_cd": 0.0, "warnings": []}
			for p_dict in [data.get("players", {}), data.get("offline_players", {})]:
				if p_dict is Dictionary:
					for p in p_dict.values():
						if p is Dictionary:
							if p.has("stats") and p.stats is Dictionary and not p.stats.has("temperature"):
								p.stats["temperature"] = 50.0
							for slot in p.get("inventory", {}).get("slots", []):
								if slot is Dictionary and not slot.is_empty():
									var idef := ItemDB.get_item(str(slot.get("id", "")))
									if idef != null and idef.spoil_time > 0.0 and not slot.has("freshness"):
										slot["freshness"] = 1.0
		elif v == 4:
			for c in data.get("creatures", []):
				if c is Dictionary:
					if not c.has("effects") or not c.effects is Dictionary:
						c["effects"] = {}
					if not c.has("behavior_state"):
						c["behavior_state"] = str(c.get("state", "idle"))
		elif v == 5:
			if not data.has("puppets") or not data.puppets is Array:
				data["puppets"] = []
			_migrate_vitality_to_temper(data)
		elif v == 6:
			if not data.has("karma") or not data.karma is Dictionary:
				data["karma"] = {"sin": 0.0, "fate": 0.0}
			if not data.has("karma_history") or not data.karma_history is Array:
				data["karma_history"] = []
			if not data.has("karma_cooldowns") or not data.karma_cooldowns is Dictionary:
				data["karma_cooldowns"] = {}
			if not data.has("npcs") or not data.npcs is Array:
				data["npcs"] = []
			if not data.has("forbidden_recipes") or not data.forbidden_recipes is Array:
				data["forbidden_recipes"] = []
		elif v == 7:
			for p_dict in [data.get("players", {}), data.get("offline_players", {})]:
				if p_dict is Dictionary:
					for p in p_dict.values():
						if p is Dictionary:
							if str(p.get("character", "")).is_empty():
								p["character"] = "beast_bloodline"
							if not p.has("ability_cds") or not p.ability_cds is Dictionary:
								p["ability_cds"] = {}
							if not p.has("rage"):
								p["rage"] = 0.0
							if not p.has("devour_history") or not p.devour_history is Array:
								p["devour_history"] = []
							if p.has("stats") and p.stats is Dictionary and not p.stats.has("base_max_health"):
								p.stats["base_max_health"] = 150.0
		elif v == 8:
			if not data.has("rituals") or not data.rituals is Array:
				data["rituals"] = []
			for p_dict in [data.get("players", {}), data.get("offline_players", {})]:
				if p_dict is Dictionary:
					for p in p_dict.values():
						if p is Dictionary:
							if not p.has("awakening_tier"):
								p["awakening_tier"] = 0
							if not p.has("skill_points"):
								p["skill_points"] = 0
							if not p.has("skills") or not p.skills is Array:
								p["skills"] = []
							if not p.has("imprints") or not p.imprints is Array:
								p["imprints"] = []
		elif v == 9:
			if not data.has("secret_realm") or not data.secret_realm is Dictionary:
				data["secret_realm"] = {"built": false, "switches_active": 0, "unlocked": false}
			for p_dict in [data.get("players", {}), data.get("offline_players", {})]:
				if p_dict is Dictionary:
					for p in p_dict.values():
						if p is Dictionary and not p.has("in_secret_realm"):
							p["in_secret_realm"] = false
		v += 1
	return data


static func _migrate_vitality_to_temper(data: Dictionary) -> void:
	for p_dict in [data.get("players", {}), data.get("offline_players", {})]:
		if not p_dict is Dictionary:
			continue
		for p in p_dict.values():
			if not p is Dictionary or not p.has("inventory") or not p.inventory is Dictionary:
				continue
			for s in p.inventory.get("slots", []):
				_convert_slot_vitality(s)
			var eq = p.inventory.get("equipment", {})
			if eq is Dictionary:
				for k in eq:
					_convert_slot_vitality(eq[k])
	for st in data.get("structures", []):
		if st is Dictionary and st.get("slots") is Array:
			for s in st.slots:
				_convert_slot_vitality(s)
	for drop in data.get("drops", []):
		if drop is Dictionary and drop.get("extra") is Dictionary:
			_convert_slot_vitality(drop.extra)


static func _convert_slot_vitality(slot) -> void:
	if not slot is Dictionary:
		return
	var hits := int(slot.get("vitality_hits", 0))
	if hits > 0 and not slot.has("temper"):
		slot["temper"] = {"type": "thanh_moc", "hits": hits}
	slot.erase("vitality_hits")


func _default_regions(seed_value: int, map_size: float) -> Array:
	var layout_script := load("res://world/simulation/world_layout.gd")
	if layout_script != null:
		return layout_script.generate(seed_value, map_size)
	return []


func list_worlds() -> Array:
	var worlds: Array = []
	for file in DirAccess.get_files_at(SAVE_DIR):
		if file.ends_with(".json") and _valid_slot(file.trim_suffix(".json")):
			worlds.append(file.trim_suffix(".json"))
	worlds.sort()
	return worlds
