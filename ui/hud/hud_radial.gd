extends Control
## Top-right world & vitals cluster: Sun/Moon Clock, Season/Weather/Temp/Biome strip, and 3 Vital Orbs.

const UITheme = preload("res://ui/theme/ui_theme.gd")
const STAT_ICONS := [
	preload("res://assets/ui/icons/ui-health.svg"),
	preload("res://assets/ui/icons/ui-stamina.svg"),
	preload("res://assets/ui/icons/ui-dao.svg"),
]

var values: Dictionary = {}
var progress := 0.0
var day_segments := 8
var dusk_segments := 6
var day_num := 1
var phase_text := ""
var season_text := ""
var weather_text := ""
var weather_kind := "clear"
var temperature := 50
var biome_text := ""
var season_warn_text := ""
var is_ghost := false
var is_frenzy := false


func _ready() -> void:
	custom_minimum_size = Vector2(246, 206)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _draw() -> void:
	var font := get_theme_font("font")
	var w := size.x

	# 1. Sun/Moon Clock centered at top-right (x = w - 123, y = 40)
	var clock := Vector2(w * 0.5, 40.0)
	draw_circle(clock, 36.0, Color(0.035, 0.055, 0.052, 0.94))
	draw_arc(clock, 36.0, 0.0, TAU, 48, UITheme.BORDER_GOLD, 2.0, true)
	draw_arc(clock, 33.0, 0.0, TAU, 48, UITheme.BORDER_GOLD_DIM, 1.0, true)

	for i in 16:
		var start := -PI / 2.0 + TAU * float(i) / 16.0
		var seg_col := Color("d4be6a") if i < day_segments else Color("cc7a4c") if i < (day_segments + dusk_segments) else Color("4a547a")
		draw_arc(clock, 26.5, start + 0.04, start + TAU / 16.0 - 0.04, 6, seg_col, 7.0, true)

	draw_circle(clock, 20.5, Color(0.05, 0.08, 0.075, 0.96))
	var hand_angle := -PI / 2.0 + TAU * progress
	var hand_tip := clock + Vector2.from_angle(hand_angle) * 28.0
	draw_line(clock + Vector2.from_angle(hand_angle) * 14.0, hand_tip, Color("fff4d4"), 2.2, true)
	draw_circle(hand_tip, 3.2, Color("ffe38a"))

	var day_str := "N%d" % day_num
	var day_sz := font.get_string_size(day_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, clock + Vector2(-day_sz.x * 0.5, 4.5), day_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.TEXT_ACCENT)

	# 2. World Status Pill (Season • Weather • Temp)
	var pill_rect := Rect2(8.0, 82.0, w - 16.0, 24.0)
	draw_rect(pill_rect, Color(0.045, 0.068, 0.064, 0.88), true)
	draw_rect(pill_rect, UITheme.BORDER_GOLD_DIM, false, 1.0)
	var status_line := "%s • %s • %d°" % [season_text, weather_text, temperature]
	if not season_warn_text.is_empty():
		status_line += " (!)"
	var st_sz := font.get_string_size(status_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(font, Vector2((w - st_sz.x) * 0.5, 98.0), status_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.TEXT_PRIMARY)

	# 3. Biome & State Line
	var sub_line := biome_text
	if is_ghost:
		sub_line += (" • " if not sub_line.is_empty() else "") + tr("UI_GHOST")
	elif is_frenzy:
		sub_line += (" • " if not sub_line.is_empty() else "") + tr("UI_FRENZY")
	if not sub_line.is_empty():
		var b_col := UITheme.TEXT_BAD if (is_ghost or is_frenzy) else UITheme.TEXT_ACCENT
		var b_sz := font.get_string_size(sub_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string_outline(font, Vector2((w - b_sz.x) * 0.5, 121.0), sub_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.02, 0.03, 0.03, 0.9))
		draw_string(font, Vector2((w - b_sz.x) * 0.5, 121.0), sub_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, b_col)

	# 4. Three Vital Orbs (Khí Huyết, Thể Lực, Đạo Tâm)
	var colors := [Color("c9524c"), Color("d4aa4c"), Color("63adae")]
	var keys := ["health", "stamina", "dao"]
	var labels := [tr("UI_HP"), tr("UI_SP"), tr("UI_DAO")]
	var spacing := 74.0
	var start_x := w * 0.5 - spacing
	for i in 3:
		var center := Vector2(start_x + float(i) * spacing, 160.0)
		var max_val := float(values.get("max_health", 150) if i == 0 else 100)
		var val := float(values.get(keys[i], 0))
		var ratio := clampf(val / maxf(1.0, max_val), 0.0, 1.0)
		var low := ratio < 0.25

		draw_circle(center, 27.0, Color(0.04, 0.06, 0.058, 0.95))
		draw_arc(center, 27.0, 0.0, TAU, 36, UITheme.BORDER_DANGER if low else UITheme.BORDER_GOLD_DIM, 1.8 if low else 1.2, true)
		draw_arc(center, 22.0, 0.0, TAU, 36, Color(0.12, 0.16, 0.15, 0.7), 4.5, true)
		if ratio > 0.005:
			draw_arc(center, 22.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 36, colors[i], 4.5, true)
		draw_texture_rect(STAT_ICONS[i], Rect2(center + Vector2(-11, -17), Vector2(22, 22)), false)

		var num_str := str(int(val))
		var num_sz := font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		draw_string_outline(font, center + Vector2(-num_sz.x * 0.5, 16.0), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(0.02, 0.03, 0.03, 0.95))
		draw_string(font, center + Vector2(-num_sz.x * 0.5, 16.0), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.TEXT_BAD if low else UITheme.TEXT_PRIMARY)

		var lbl_sz := font.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string_outline(font, center + Vector2(-lbl_sz.x * 0.5, 40.0), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0.02, 0.03, 0.03, 0.9))
		draw_string(font, center + Vector2(-lbl_sz.x * 0.5, 40.0), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.TEXT_MUTED)
