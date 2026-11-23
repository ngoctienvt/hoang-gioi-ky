extends PanelContainer

signal action(verb: String, args: Dictionary)
signal close_requested

const W = preload("res://ui/hud/hud_widgets.gd")

var box: VBoxContainer
var npc_uid := -1


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	custom_minimum_size = Vector2(340, 220)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -170
	offset_right = 170
	offset_top = -110
	offset_bottom = 110
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	hide()


func open_npc(npc: Dictionary) -> void:
	npc_uid = int(npc.get("uid", -1))
	W.clear(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := W.label(head, "WORLD_WANDERER")
	title.theme_type_variation = &"LabelHeading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := W.button(head, "", func(): close_requested.emit(); hide(), "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(28, 28)

	W.divider(box)

	for req in npc.get("requests", []):
		var lbl := Label.new()
		lbl.text = "• %s ×%d" % [W.item_name(str(req.get("id", ""))), int(req.get("count", 1))]
		box.add_child(lbl)
	W.button(box, "UI_FULFILL_REQUEST", func():
		action.emit("fulfill_request", {"uid": npc_uid})
		close_requested.emit()
		hide()
	, "ButtonPrimary")
	show()
