extends VBoxContainer
## Clean left-aligned Main Menu with navigation cards (Home -> Host / Join) instead of one cramped form.

signal host_requested(options: Dictionary)
signal join_requested(address: String, player_name: String)
signal settings_requested

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

var home_page: VBoxContainer
var host_page: VBoxContainer
var join_page: VBoxContainer

var player_name_host: LineEdit
var player_name_join: LineEdit
var seed_value: LineEdit
var address: LineEdit
var length_value: SpinBox
var death: OptionButton
var worlds: OptionButton


func _ready() -> void:
	add_theme_constant_override("separation", 12)

	var title := W.label(self, "GAME_TITLE")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)

	var subtitle := W.label(self, "UI_CHARACTER_DESC")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", UITheme.TEXT_MUTED)

	W.divider(self)

	_build_home_page()
	_build_host_page()
	_build_join_page()
	_show_page(home_page)


func _build_home_page() -> void:
	home_page = VBoxContainer.new()
	home_page.add_theme_constant_override("separation", 10)
	add_child(home_page)

	var play_btn := W.button(home_page, "UI_PLAY_HOST", func(): _show_page(host_page), "ButtonPrimary", "Khởi Hành (Chơi Đơn / Host)")
	play_btn.custom_minimum_size.y = 44
	var join_btn := W.button(home_page, "UI_JOIN_LAN", func(): _show_page(join_page), "", "Tham Gia LAN")
	join_btn.custom_minimum_size.y = 40
	var set_btn := W.button(home_page, "UI_SETTINGS", func(): settings_requested.emit())
	set_btn.custom_minimum_size.y = 38
	var quit_btn := W.button(home_page, "UI_QUIT", func(): get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST), "ButtonSubtle")
	quit_btn.custom_minimum_size.y = 36


func _build_host_page() -> void:
	host_page = VBoxContainer.new()
	host_page.add_theme_constant_override("separation", 8)
	add_child(host_page)

	var head := HBoxContainer.new()
	host_page.add_child(head)
	W.button(head, "", func(): _show_page(home_page), "ButtonSubtle", "← Quay lại")
	var h_lbl := W.section_header(head, "UI_HOST")
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	player_name_host = _field(host_page, "UI_NAME", "")

	W.label(host_page, "UI_WORLD_SLOT", "Thế giới")
	worlds = OptionButton.new()
	refresh_worlds()
	host_page.add_child(worlds)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	host_page.add_child(row)

	var seed_col := VBoxContainer.new()
	seed_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(seed_col)
	seed_value = _field(seed_col, "UI_SEED", "12345")

	var len_col := VBoxContainer.new()
	len_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(len_col)
	W.label(len_col, "UI_DAY_LENGTH")
	length_value = SpinBox.new()
	length_value.min_value = 60
	length_value.max_value = 1800
	length_value.value = 480
	length_value.step = 30
	len_col.add_child(length_value)

	W.label(host_page, "UI_DEATH_RULE", "Quy tắc tử vong")
	death = OptionButton.new()
	death.add_item(tr("UI_CONTINUE"))
	death.add_item(tr("UI_RESET"))
	host_page.add_child(death)

	var start_btn := W.button(host_page, "UI_HOST", _host, "ButtonPrimary")
	start_btn.custom_minimum_size.y = 42


func _build_join_page() -> void:
	join_page = VBoxContainer.new()
	join_page.add_theme_constant_override("separation", 10)
	add_child(join_page)

	var head := HBoxContainer.new()
	join_page.add_child(head)
	W.button(head, "", func(): _show_page(home_page), "ButtonSubtle", "← Quay lại")
	var j_lbl := W.section_header(head, "UI_JOIN")
	j_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	j_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	player_name_join = _field(join_page, "UI_NAME", "")
	address = _field(join_page, "UI_IP", "127.0.0.1")

	var hint := W.label(join_page, "UI_LAN_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.theme_type_variation = &"LabelMuted"

	var join_btn := W.button(join_page, "UI_JOIN", func():
		join_requested.emit(address.text.strip_edges(), _name(player_name_join))
	, "ButtonPrimary")
	join_btn.custom_minimum_size.y = 42


func _show_page(page: VBoxContainer) -> void:
	home_page.visible = (page == home_page)
	host_page.visible = (page == host_page)
	join_page.visible = (page == join_page)


func refresh_worlds() -> void:
	if not worlds:
		return
	worlds.clear()
	worlds.add_item(tr("UI_NEW_WORLD"))
	var directory := DirAccess.open("user://saves/")
	if directory:
		for file in directory.get_files():
			if file.ends_with(".json"):
				worlds.add_item(file.get_basename())
				worlds.set_item_metadata(worlds.item_count - 1, file.get_basename())


func _field(parent: Node, key: String, value: String) -> LineEdit:
	W.label(parent, key)
	var field := LineEdit.new()
	field.text = value
	field.max_length = 64
	parent.add_child(field)
	return field


func _name(field: LineEdit) -> String:
	var txt := field.text.strip_edges() if field != null else ""
	return txt if not txt.is_empty() else tr("UI_TRAVELER")


func _host() -> void:
	host_requested.emit({
		"name": _name(player_name_host),
		"seed": int(seed_value.text) if seed_value.text.is_valid_int() else seed_value.text.hash(),
		"day_length": length_value.value,
		"death_mode": "continue" if death.selected == 0 else "reset",
		"load_slot": worlds.get_item_metadata(worlds.selected) if worlds.selected > 0 else "",
	})
