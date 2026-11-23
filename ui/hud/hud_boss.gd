extends PanelContainer

const W = preload("res://ui/hud/hud_widgets.gd")

var title_lbl: Label
var hp_bar: ProgressBar
var status_lbl: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-180, 96)
	custom_minimum_size = Vector2(360, 56)
	var box := VBoxContainer.new()
	add_child(box)
	title_lbl = W.label(box, "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(340, 14)
	hp_bar.show_percentage = false
	box.add_child(hp_bar)
	status_lbl = W.label(box, "")
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
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
