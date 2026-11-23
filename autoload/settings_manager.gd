extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_BINDINGS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"ability_1": KEY_Q,
	"ability_2": KEY_E,
	"ability_3": KEY_R,
	"quick_work": KEY_F,
	"interact": KEY_SPACE,
	"craft_menu": KEY_TAB,
	"codex": KEY_B,
	"awakening": KEY_K,
}

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var muted: bool = false
var window_mode: String = "windowed"
var shadows: bool = true
var fog: bool = true
var vsync: bool = true
var tutorial_completed: bool = false
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate()


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings(path: String = SETTINGS_PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
	muted = bool(cfg.get_value("audio", "muted", false))
	window_mode = str(cfg.get_value("graphics", "window_mode", "windowed"))
	shadows = bool(cfg.get_value("graphics", "shadows", true))
	fog = bool(cfg.get_value("graphics", "fog", true))
	vsync = bool(cfg.get_value("graphics", "vsync", true))
	tutorial_completed = bool(cfg.get_value("tutorial", "completed", false))
	for action_name in DEFAULT_BINDINGS:
		bindings[action_name] = int(cfg.get_value("bindings", action_name, DEFAULT_BINDINGS[action_name]))


func save_settings(path: String = SETTINGS_PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("graphics", "window_mode", window_mode)
	cfg.set_value("graphics", "shadows", shadows)
	cfg.set_value("graphics", "fog", fog)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.set_value("tutorial", "completed", tutorial_completed)
	for action_name in bindings:
		cfg.set_value("bindings", action_name, int(bindings[action_name]))
	return cfg.save(path)


func apply_all() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, muted)
		var db := linear_to_db(maxf(0.0001, master_volume)) if not muted else -80.0
		AudioServer.set_bus_volume_db(bus, db)
	if DisplayServer.get_name() != "headless":
		match window_mode:
			"fullscreen":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			"borderless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			_:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	settings_changed.emit()


func key_for(action_name: String) -> int:
	return int(bindings.get(action_name, DEFAULT_BINDINGS.get(action_name, KEY_NONE)))


func key_label(action_name: String) -> String:
	return OS.get_keycode_string(key_for(action_name))


func rebind(action_name: String, keycode: int) -> bool:
	if not bindings.has(action_name) or keycode <= 0:
		return false
	var prev_key := int(bindings[action_name])
	for other in bindings:
		if other != action_name and int(bindings[other]) == keycode:
			bindings[other] = prev_key
			break
	bindings[action_name] = keycode
	save_settings()
	settings_changed.emit()
	return true


func reset_bindings() -> void:
	bindings = DEFAULT_BINDINGS.duplicate()
	save_settings()
	settings_changed.emit()


func set_tutorial_completed(done: bool) -> void:
	tutorial_completed = done
	save_settings()
	settings_changed.emit()
