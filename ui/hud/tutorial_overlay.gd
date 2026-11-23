extends PanelContainer
## Compact Tutorial card anchored cleanly in top-left below Karma without colliding with rail or hotbar.

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

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
	theme_type_variation = &"PanelPrimary"
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	offset_left = 12
	offset_right = 312
	offset_top = 152
	offset_bottom = 290

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	step_lbl = W.label(head, "")
	step_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_lbl.add_theme_font_size_override("font_size", 12)
	step_lbl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	W.button(head, "UI_SKIP", _finish, "ButtonSubtle")

	body_lbl = W.label(box, "")
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size.x = 276
	body_lbl.add_theme_font_size_override("font_size", 13)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	box.add_child(nav)
	prev_btn = W.button(nav, "UI_PREV", func(): _set_step(step_idx - 1), "ButtonSubtle")
	prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn = W.button(nav, "UI_NEXT", func():
		if step_idx >= STEP_KEYS.size() - 1:
			_finish()
		else:
			_set_step(step_idx + 1)
	, "ButtonPrimary")
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_step(0)
	if SettingsManager.tutorial_completed or "--probe" in OS.get_cmdline_user_args():
		hide()


func reopen() -> void:
	_set_step(0)
	show()


func _set_step(idx: int) -> void:
	step_idx = clampi(idx, 0, STEP_KEYS.size() - 1)
	step_lbl.text = tr("UI_TUTORIAL_STEP") % [step_idx + 1, STEP_KEYS.size()]
	body_lbl.text = tr(STEP_KEYS[step_idx])
	prev_btn.disabled = step_idx == 0
	next_btn.text = tr("UI_FINISH") if step_idx >= STEP_KEYS.size() - 1 else tr("UI_NEXT")


func _finish() -> void:
	SettingsManager.set_tutorial_completed(true)
	hide()
