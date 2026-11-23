extends PanelContainer
## Centered top Boss Health Bar with cinnabar-gold styling.

const UITheme = preload("res://ui/theme/ui_theme.gd")

var title_lbl: Label
var hp_bar: ProgressBar
var status_lbl: Label


func _ready() -> void:
	theme_type_variation = &"PanelPrimary"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -200
	offset_right = 200
	offset_top = 12
	offset_bottom = 74
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	add_child(box)

	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)

	title_lbl = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(title_lbl)

	status_lbl = Label.new()
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(status_lbl)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(360, 12)
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("b83b3b")
	fill.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(hp_bar)
	hide()


func refresh(state: Dictionary, player: Dictionary) -> void:
	if player.is_empty():
		hide()
		return
	var ppos: Array = player.get("position", [0.0, 0.0, 0.0])
	var p2 := Vector2(float(ppos[0]), float(ppos[2]))
	var nearest: Dictionary = {}
	var best_dist := 25.0
	for c in state.get("creatures", []):
		if not c.get("is_boss", false) or float(c.get("health", 0.0)) <= 0.0:
			continue
		var cp: Array = c.get("position", [0.0, 0.0, 0.0])
		var d := p2.distance_to(Vector2(float(cp[0]), float(cp[2])))
		if d < best_dist:
			best_dist = d
			nearest = c
	if nearest.is_empty():
		hide()
		return
	show()
	var kind := str(nearest.get("kind", "boss"))
	title_lbl.text = tr("WORLD_" + kind.to_upper())
	hp_bar.max_value = maxf(1.0, float(nearest.get("max_health", 450.0)))
	hp_bar.value = float(nearest.get("health", 0.0))
	status_lbl.text = "%d / %d" % [int(hp_bar.value), int(hp_bar.max_value)]
