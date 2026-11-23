extends PanelContainer

const W = preload("res://ui/hud/hud_widgets.gd")

var content: VBoxContainer
var capturing_action := ""
var key_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	position = Vector2(-230, -240)
	custom_minimum_size = Vector2(460, 480)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	hide()


func open_settings() -> void:
	capturing_action = ""
	_build()
	show()


func _build() -> void:
	W.clear(content)
	key_buttons.clear()
	var head := HBoxContainer.new()
	content.add_child(head)
	W.label(head, "UI_SETTINGS_TITLE")
	W.button(head, "UI_CLOSE", func(): capturing_action = ""; hide())

	W.label(content, "UI_SETTINGS_AUDIO")
	_slider("UI_MASTER_VOL", SettingsManager.master_volume, func(v: float):
		SettingsManager.master_volume = v
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

	W.label(content, "UI_SETTINGS_GRAPHICS")
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

	W.label(content, "UI_SETTINGS_KEYS")
	for action_name in SettingsManager.DEFAULT_BINDINGS:
		var row := HBoxContainer.new()
		content.add_child(row)
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = tr("KEY_" + action_name.to_upper())
		row.add_child(lbl)
		var btn := Button.new()
		btn.text = SettingsManager.key_label(action_name)
		var act: String = str(action_name)
		btn.pressed.connect(func():
			capturing_action = act
			btn.text = tr("UI_PRESS_KEY")
		)
		row.add_child(btn)
		key_buttons[action_name] = btn

	var foot := HBoxContainer.new()
	content.add_child(foot)
	W.button(foot, "UI_RESET_KEYS", func():
		SettingsManager.reset_bindings()
		_build()
	)
	W.button(foot, "UI_RESET_TUTORIAL", func():
		SettingsManager.set_tutorial_completed(false)
	)


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
	s.custom_minimum_size.x = 160
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
