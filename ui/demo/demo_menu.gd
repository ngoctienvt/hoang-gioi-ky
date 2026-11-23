extends VBoxContainer

signal host_requested(options: Dictionary)
signal join_requested(address: String, player_name: String)
const W = preload("res://ui/demo/demo_widgets.gd")
var player_name: LineEdit
var seed_value: LineEdit
var address: LineEdit
var length_value: SpinBox
var death: OptionButton
var worlds: OptionButton

func _ready() -> void:
	W.label(self, "GAME_TITLE").add_theme_font_size_override("font_size", 36)
	W.label(self, "DEMO_CHARACTER")
	W.label(self, "DEMO_CHARACTER_DESC")
	player_name = _field("DEMO_NAME", "")
	seed_value = _field("DEMO_SEED", "12345")
	W.label(self, "DEMO_DAY_LENGTH")
	length_value = SpinBox.new()
	length_value.min_value = 60
	length_value.max_value = 1800
	length_value.value = 480
	length_value.step = 30
	add_child(length_value)
	death = OptionButton.new()
	death.add_item(tr("DEMO_CONTINUE"))
	death.add_item(tr("DEMO_RESET"))
	add_child(death)
	worlds = OptionButton.new()
	refresh_worlds()
	add_child(worlds)
	W.button(self, "DEMO_HOST", _host)
	address = _field("DEMO_IP", "127.0.0.1")
	W.button(self, "DEMO_JOIN", func(): join_requested.emit(address.text.strip_edges(), _name()))
	W.label(self, "DEMO_LAN_HINT")
	W.button(self, "DEMO_QUIT", func(): get_tree().quit())

func refresh_worlds() -> void:
	if not worlds: return
	worlds.clear()
	worlds.add_item(tr("DEMO_NEW_WORLD"))
	var directory := DirAccess.open("user://saves/")
	if directory:
		for file in directory.get_files():
			if file.ends_with(".json"):
				worlds.add_item(file.get_basename())
				worlds.set_item_metadata(worlds.item_count - 1, file.get_basename())

func _field(key: String, value: String) -> LineEdit:
	W.label(self, key)
	var field := LineEdit.new()
	field.text = value
	field.max_length = 64
	add_child(field)
	return field

func _name() -> String:
	return player_name.text.strip_edges() if not player_name.text.strip_edges().is_empty() else tr("DEMO_TRAVELER")

func _host() -> void:
	host_requested.emit({"name": _name(), "seed": int(seed_value.text) if seed_value.text.is_valid_int() else seed_value.text.hash(), "day_length": length_value.value, "death_mode": "continue" if death.selected == 0 else "reset", "load_slot": worlds.get_item_metadata(worlds.selected) if worlds.selected > 0 else ""})
