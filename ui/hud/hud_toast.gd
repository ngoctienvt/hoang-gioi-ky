extends VBoxContainer
## Non-blocking auto-fading toast notifications centered near the top of the viewport.

const UITheme = preload("res://ui/theme/ui_theme.gd")
const MAX_VISIBLE := 3
const HOLD_SECONDS := 2.8

var _last_text := ""
var _last_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_top = 82
	offset_bottom = 220
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 6)


func show_message(text: String, kind: String = "info") -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if clean == _last_text and (now - _last_time) < 1.2:
		return
	_last_text = clean
	_last_time = now

	while get_child_count() >= MAX_VISIBLE:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()

	var accent := UITheme.BORDER_GOLD
	var bg := Color(0.055, 0.082, 0.078, 0.94)
	match kind:
		"error":
			accent = UITheme.BORDER_DANGER
			bg = Color(0.145, 0.055, 0.055, 0.95)
		"warn":
			accent = UITheme.TEXT_WARN
			bg = Color(0.135, 0.098, 0.045, 0.95)
		"success":
			accent = UITheme.TEXT_GOOD
			bg = Color(0.055, 0.125, 0.085, 0.95)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = accent
	sb.border_width_left = 4
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_size = 5
	sb.shadow_color = Color(0, 0, 0, 0.45)
	pill.add_theme_stylebox_override("panel", sb)
	center.add_child(pill)

	var lbl := Label.new()
	lbl.text = clean
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	pill.add_child(lbl)

	center.modulate.a = 0.0
	var tw := center.create_tween()
	tw.tween_property(center, "modulate:a", 1.0, 0.16)
	tw.tween_interval(HOLD_SECONDS)
	tw.tween_property(center, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		if is_instance_valid(center):
			center.queue_free()
	)
