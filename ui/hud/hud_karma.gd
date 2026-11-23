extends VBoxContainer
## Compact top-left Karma display (Nghiệp & Duyên) with threshold tick marks at 30 / 60 / 100.

const UITheme = preload("res://ui/theme/ui_theme.gd")

var sin_val_lbl: Label
var fate_val_lbl: Label
var sin_bar: _TickBar
var fate_bar: _TickBar


func _ready() -> void:
	add_theme_constant_override("separation", 5)

	var sin_head := HBoxContainer.new()
	add_child(sin_head)
	var sin_title := Label.new()
	sin_title.text = tr("UI_KARMA_SIN")
	sin_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sin_title.add_theme_font_size_override("font_size", 12)
	sin_title.add_theme_color_override("font_color", Color("e89a94"))
	sin_head.add_child(sin_title)
	sin_val_lbl = Label.new()
	sin_val_lbl.text = "0 / 120"
	sin_val_lbl.add_theme_font_size_override("font_size", 12)
	sin_val_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	sin_head.add_child(sin_val_lbl)

	sin_bar = _TickBar.new(Color("b6444a"))
	sin_bar.tooltip_text = "%s (Mốc: 30 | 60 | 100)" % tr("UI_KARMA_SIN")
	add_child(sin_bar)

	var fate_head := HBoxContainer.new()
	add_child(fate_head)
	var fate_title := Label.new()
	fate_title.text = tr("UI_KARMA_FATE")
	fate_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fate_title.add_theme_font_size_override("font_size", 12)
	fate_title.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	fate_head.add_child(fate_title)
	fate_val_lbl = Label.new()
	fate_val_lbl.text = "0 / 120"
	fate_val_lbl.add_theme_font_size_override("font_size", 12)
	fate_val_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	fate_head.add_child(fate_val_lbl)

	fate_bar = _TickBar.new(Color("d4b464"))
	fate_bar.tooltip_text = "%s (Mốc: 30 | 60 | 100)" % tr("UI_KARMA_FATE")
	add_child(fate_bar)


func update_karma(karma: Dictionary) -> void:
	var s := float(karma.get("sin", 0.0))
	var f := float(karma.get("fate", 0.0))
	sin_bar.set_val(s)
	fate_bar.set_val(f)
	sin_val_lbl.text = "%d / 120" % int(s)
	fate_val_lbl.text = "%d / 120" % int(f)


class _TickBar extends Control:
	var fill_color: Color
	var value := 0.0
	const MAX_VAL := 120.0
	const TICKS := [30.0, 60.0, 100.0]

	func _init(col: Color) -> void:
		fill_color = col
		custom_minimum_size = Vector2(186, 9)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func set_val(v: float) -> void:
		if not is_equal_approx(value, v):
			value = clampf(v, 0.0, MAX_VAL)
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.03, 0.045, 0.043, 0.95), true)
		var fill_w := size.x * clampf(value / MAX_VAL, 0.0, 1.0)
		if fill_w > 0.5:
			draw_rect(Rect2(1.0, 1.0, maxf(0.0, fill_w - 2.0), size.y - 2.0), fill_color, true)
		for tick in TICKS:
			var tx: float = size.x * (float(tick) / MAX_VAL)
			draw_line(Vector2(tx, 0.0), Vector2(tx, size.y), Color(0.95, 0.88, 0.72, 0.45), 1.0)
		draw_rect(rect, Color(0.56, 0.46, 0.27, 0.55), false, 1.0)
