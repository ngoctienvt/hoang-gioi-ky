extends Node
const SAVE_DIR = "user://saves/"
const MAX_SAVE_BYTES = 16000000
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
	var text = JSON.stringify({"version": 1, "state": JSON.from_native(state)})
	if text.length() > MAX_SAVE_BYTES:
		return ERR_OUT_OF_MEMORY
	var result = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if result != OK:
		return result
	var path = SAVE_DIR + slot + ".json"
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot write save")
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	result = DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		push_error("[SaveManager] Cannot replace save: %d" % result)
	return result
func load_world(slot: String = "world") -> Dictionary:
	if not _valid_slot(slot):
		return {}
	var file = FileAccess.open(SAVE_DIR + slot + ".json", FileAccess.READ)
	if file == null or file.get_length() > MAX_SAVE_BYTES:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or parsed.get("version") != 1:
		push_warning("[SaveManager] Invalid save envelope")
		return {}
	var state = JSON.to_native(parsed.get("state"))
	return state if state is Dictionary else {}
func list_worlds() -> Array:
	var worlds: Array = []
	for file in DirAccess.get_files_at(SAVE_DIR):
		if file.ends_with(".json") and _valid_slot(file.trim_suffix(".json")):
			worlds.append(file.trim_suffix(".json"))
	worlds.sort()
	return worlds
