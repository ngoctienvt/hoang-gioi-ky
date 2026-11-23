extends PanelContainer

signal action(verb: String, args: Dictionary)
signal close_requested

const W = preload("res://ui/hud/hud_widgets.gd")

var box: VBoxContainer
var npc_uid := -1


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	custom_minimum_size = Vector2(360, 240)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -180
	offset_right = 180
	offset_top = -120
	offset_bottom = 120
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	hide()


func open_npc(npc: Dictionary) -> void:
	npc_uid = int(npc.get("uid", -1))
	W.clear(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := W.label(head, "WORLD_MERCHANT")
	title.theme_type_variation = &"LabelHeading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := W.button(head, "", func(): close_requested.emit(); hide(), "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(28, 28)

	W.divider(box)

	var offers: Array = npc.get("offers", [])
	for i in offers.size():
		var o: Dictionary = offers[i]
		var idx := i
		var text := "%s ×%d — %d %s" % [W.item_name(str(o.get("id", ""))), int(o.get("count", 1)), int(o.get("price", 1)), W.item_name(str(o.get("currency", "spirit_stone")))]
		var btn := Button.new()
		btn.text = text
		btn.pressed.connect(func(): action.emit("trade", {"uid": npc_uid, "offer": idx}))
		box.add_child(btn)
	show()
