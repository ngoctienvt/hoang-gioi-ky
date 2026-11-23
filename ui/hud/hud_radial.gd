extends Control

var values: Dictionary = {}
var progress := 0.0
var day_segments := 8
var dusk_segments := 6
const STAT_ICONS = [preload("res://assets/ui/icons/ui-health.svg"), preload("res://assets/ui/icons/ui-stamina.svg"), preload("res://assets/ui/icons/ui-dao.svg")]

func _ready() -> void:
	custom_minimum_size = Vector2(220, 162)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var colors := [Color("b44d48"), Color("c5a04b"), Color("659e9f")]
	var keys := ["health", "stamina", "dao"]
	for i in 3:
		var center := Vector2(34 + i * 72, 112)
		draw_circle(center, 27, Color("a18348"))
		draw_circle(center, 24, Color("192725"))
		var value := float(values.get(keys[i], 0))
		draw_arc(center, 21, -PI / 2, -PI / 2 + TAU * clampf(value / float(values.get("max_health", 150) if i == 0 else 100), 0, 1), 36, colors[i], 5, true)
		draw_texture_rect(STAT_ICONS[i], Rect2(center + Vector2(-14, -18), Vector2(28, 28)), false)
		draw_string(font, center + Vector2(-12, 17), str(int(value)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("eee0ba"))
		draw_string(font, center + Vector2(-25, 43), tr(["UI_HP", "UI_SP", "UI_DAO"][i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("eee0ba"))
	var clock := Vector2(106, 36)
	draw_circle(clock, 28, Color("20292a"))
	for i in 16:
		var start := -PI / 2 + TAU * i / 16.0
		var color := Color("c7b96f") if i < day_segments else Color("c27651") if i < (day_segments + dusk_segments) else Color("535875")
		draw_arc(clock, 22, start + 0.03, start + TAU / 16 - 0.03, 6, color, 9, true)
	draw_line(clock, clock + Vector2.from_angle(-PI / 2 + TAU * progress) * 21, Color.WHITE, 2, true)
