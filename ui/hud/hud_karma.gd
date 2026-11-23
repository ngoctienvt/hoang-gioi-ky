extends VBoxContainer

const W = preload("res://ui/hud/hud_widgets.gd")

var sin_bar: ProgressBar
var fate_bar: ProgressBar
var sin_label: Label
var fate_label: Label


func _ready() -> void:
	sin_label = W.label(self, "UI_KARMA_SIN")
	sin_bar = _make_bar(Color("8c3838"))
	fate_label = W.label(self, "UI_KARMA_FATE")
	fate_bar = _make_bar(Color("d4b668"))


func _make_bar(col: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 120.0
	bar.custom_minimum_size = Vector2(180, 14)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)
	return bar


func update_karma(karma: Dictionary) -> void:
	var s := float(karma.get("sin", 0.0))
	var f := float(karma.get("fate", 0.0))
	sin_bar.value = s
	fate_bar.value = f
	sin_label.text = "%s: %d / 120 (30|60|100)" % [tr("UI_KARMA_SIN"), int(s)]
	fate_label.text = "%s: %d / 120 (30|60|100)" % [tr("UI_KARMA_FATE"), int(f)]
