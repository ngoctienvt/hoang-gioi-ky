extends PanelContainer
## Tabbed Settings modal (Âm thanh / Đồ họa / Phím tắt) with clean ESC handling.

signal close_requested

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

var root_box: VBoxContainer
var content: VBoxContainer
var tab_idx := 0
var capturing_action := ""
var key_buttons: Dictionary = {}


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(520, 480)
	offset_left = -260
	offset_right = 260
	offset_top = -240
	offset_bottom = 240

	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	add_child(root_box)
	hide()


func open_settings() -> void:
	capturing_action = ""
	_build()
	show()


func _build() -> void:
	W.clear(root_box)
	key_buttons.clear()

	var head := HBoxContainer.new()
	root_box.add_child(head)
	var title := W.label(head, "UI_SETTINGS_TITLE")
	title.theme_type_variation = &"LabelTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := W.button(head, "", func():
		capturing_action = ""
		close_requested.emit()
		hide()
	, "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(30, 30)

	# Tab strip
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	root_box.add_child(tabs)
	var tab_keys := ["UI_SETTINGS_AUDIO", "UI_SETTINGS_GRAPHICS", "UI_SETTINGS_KEYS"]
	for i in tab_keys.size():
		var idx := i
		var tb := W.button(tabs, tab_keys[i], func():
			tab_idx = idx
			capturing_action = ""
			_build()
		, "ButtonPrimary" if tab_idx == i else "ButtonSubtle")
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	W.divider(root_box)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	match tab_idx:
		0:
			_build_audio()
		1:
			_build_graphics()
		_:
			_build_keys()


func _build_audio() -> void:
	_slider("UI_MASTER_VOL", SettingsManager.master_volume, func(v: float):
		SettingsManager.master_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_slider("UI_MUSIC_VOL", SettingsManager.music_volume, func(v: float):
		SettingsManager.music_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_slider("UI_AMBIENT_VOL", SettingsManager.ambient_volume, func(v: float):
		SettingsManager.ambient_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_slider("UI_SFX_VOL", SettingsManager.sfx_volume, func(v: float):
		SettingsManager.sfx_volume = v
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_toggle("UI_MUTE", SettingsManager.muted, func(on: bool):
		SettingsManager.muted = on
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)


func _build_graphics() -> void:
	_toggle("UI_SHADOWS", SettingsManager.shadows, func(on: bool):
		SettingsManager.shadows = on
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_toggle("UI_FOG", SettingsManager.fog, func(on: bool):
		SettingsManager.fog = on
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	_toggle("UI_VSYNC", SettingsManager.vsync, func(on: bool):
		SettingsManager.vsync = on
		SettingsManager.save_settings()
		SettingsManager.apply_all()
	)
	W.divider(content)
	W.button(content, "UI_RESET_TUTORIAL", func():
		SettingsManager.set_tutorial_completed(false)
	)


func _build_keys() -> void:
	for action_name in SettingsManager.DEFAULT_BINDINGS:
		var row := HBoxContainer.new()
		content.add_child(row)
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = tr("KEY_" + action_name.to_upper())
		row.add_child(lbl)
		var btn := Button.new()
		btn.custom_minimum_size.x = 110
		btn.text = SettingsManager.key_label(action_name)
		var act: String = str(action_name)
		btn.pressed.connect(func():
			capturing_action = act
			btn.text = tr("UI_PRESS_KEY")
		)
		row.add_child(btn)
		key_buttons[action_name] = btn

	W.divider(content)
	W.button(content, "UI_RESET_KEYS", func():
		SettingsManager.reset_bindings()
		_build()
	, "ButtonSubtle")


func _slider(key: String, initial: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var lbl := W.label(row, key)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = initial
	s.custom_minimum_size.x = 190
	s.value_changed.connect(cb)
	row.add_child(s)


func _toggle(key: String, initial: bool, cb: Callable) -> void:
	var c := CheckButton.new()
	c.text = tr(key)
	c.button_pressed = initial
	c.toggled.connect(cb)
	content.add_child(c)


func _input(event: InputEvent) -> void:
	if not visible or capturing_action.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			SettingsManager.rebind(capturing_action, event.keycode)
		capturing_action = ""
		_build()
		get_viewport().set_input_as_handled()
