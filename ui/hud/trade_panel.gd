extends PanelContainer

signal action(verb: String, args: Dictionary)
const W = preload("res://ui/hud/hud_widgets.gd")

var box: VBoxContainer
var npc_uid := -1


func _ready() -> void:
	custom_minimum_size = Vector2(280, 220)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box = VBoxContainer.new()
	add_child(box)
	hide()


func open_npc(npc: Dictionary) -> void:
	npc_uid = int(npc.get("uid", -1))
	W.clear(box)
	W.label(box, "WORLD_MERCHANT")
	var offers: Array = npc.get("offers", [])
	for i in offers.size():
		var o: Dictionary = offers[i]
		var idx := i
		var text := "%s ×%d — %d %s" % [W.item_name(str(o.get("id", ""))), int(o.get("count", 1)), int(o.get("price", 1)), W.item_name(str(o.get("currency", "spirit_stone")))]
		var btn := Button.new()
		btn.text = text
		btn.pressed.connect(func(): action.emit("trade", {"uid": npc_uid, "offer": idx}))
		box.add_child(btn)
	W.button(box, "UI_CLOSE", func(): hide())
	show()
