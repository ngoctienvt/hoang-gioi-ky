extends PanelContainer

const W = preload("res://ui/hud/hud_widgets.gd")

const STEP_KEYS := [
	"TUT_STEP_1",
	"TUT_STEP_2",
	"TUT_STEP_3",
	"TUT_STEP_4",
	"TUT_STEP_5",
]

var step_idx := 0
var body_lbl: Label
var step_lbl: Label
var prev_btn: Button
var next_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 14
	offset_right = 340
	offset_top = -350
	offset_bottom = -214
	var box := VBoxContainer.new()
	add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	step_lbl = W.label(head, "")
	step_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	W.button(head, "UI_SKIP", _finish)
	body_lbl = W.label(box, "")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size.x = 300
	var nav := HBoxContainer.new()
	box.add_child(nav)
	prev_btn = W.button(nav, "UI_PREV", func(): _set_step(step_idx - 1))
	next_btn = W.button(nav, "UI_NEXT", func():
		if step_idx >= STEP_KEYS.size() - 1:
			_finish()
		else:
			_set_step(step_idx + 1)
	)
	_set_step(0)
	if SettingsManager.tutorial_completed or "--probe" in OS.get_cmdline_user_args():
		hide()


func _set_step(idx: int) -> void:
	step_idx = clampi(idx, 0, STEP_KEYS.size() - 1)
	step_lbl.text = tr("UI_TUTORIAL_STEP") % [step_idx + 1, STEP_KEYS.size()]
	body_lbl.text = tr(STEP_KEYS[step_idx])
	prev_btn.disabled = step_idx == 0
	next_btn.text = tr("UI_FINISH") if step_idx >= STEP_KEYS.size() - 1 else tr("UI_NEXT")


func _finish() -> void:
	SettingsManager.set_tutorial_completed(true)
	hide()
