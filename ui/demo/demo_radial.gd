extends Control

var values: Dictionary = {}
var progress := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var colors := [Color("b44d48"), Color("c5a04b"), Color("659e9f")]
	var keys := ["health", "stamina", "dao"]
	for i in 3:
		var center := Vector2(28 + i * 68, 30)
		draw_circle(center, 27, Color("a18348"))
		draw_circle(center, 24, Color("192725"))
		var value := float(values.get(keys[i], 0))
		draw_arc(center, 21, -PI / 2, -PI / 2 + TAU * clampf(value / float(values.get("max_health", 150) if i == 0 else 100), 0, 1), 36, colors[i], 5, true)
		draw_string(font, center + Vector2(-12, 6), str(int(value)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("eee0ba"))
		draw_string(font, center + Vector2(-25, 42), tr(["DEMO_HP", "DEMO_SP", "DEMO_DAO"][i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("eee0ba"))
	var clock := Vector2(244, 30)
	draw_circle(clock, 28, Color("20292a"))
	for i in 16:
		var start := -PI / 2 + TAU * i / 16.0
		var color := Color("c7b96f") if i < 8 else Color("c27651") if i < 14 else Color("535875")
		draw_arc(clock, 22, start + 0.03, start + TAU / 16 - 0.03, 6, color, 9, true)
	draw_line(clock, clock + Vector2.from_angle(-PI / 2 + TAU * progress) * 21, Color.WHITE, 2, true)
