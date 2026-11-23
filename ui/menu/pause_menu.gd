extends PanelContainer
## Centered Pause Menu triggered by ESC or the Top-Left Menu button.

signal resume_requested
signal save_requested
signal settings_requested
signal tutorial_requested
signal leave_requested

const W = preload("res://ui/hud/hud_widgets.gd")


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(320, 0)
	offset_left = -160
	offset_right = 160
	offset_top = -170
	offset_bottom = 170

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := W.label(box, "UI_PAUSE_TITLE", "Tạm Dừng")
	title.theme_type_variation = &"LabelTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	W.divider(box)

	var resume_btn := W.button(box, "UI_RESUME", func(): resume_requested.emit(), "ButtonPrimary", "Tiếp tục")
	resume_btn.custom_minimum_size.y = 40

	W.button(box, "UI_SAVE", func(): save_requested.emit())
	W.button(box, "UI_SETTINGS", func(): settings_requested.emit())
	W.button(box, "UI_TUTORIAL", func(): tutorial_requested.emit(), "", "Hướng dẫn")
	W.divider(box)
	W.button(box, "UI_LEAVE", func(): leave_requested.emit(), "ButtonDanger")
	hide()
