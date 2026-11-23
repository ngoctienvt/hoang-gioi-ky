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
	W.label(box, "WORLD_WANDERER")
	for req in npc.get("requests", []):
		var lbl := Label.new()
		lbl.text = "%s ×%d" % [W.item_name(str(req.get("id", ""))), int(req.get("count", 1))]
		box.add_child(lbl)
	W.button(box, "UI_FULFILL_REQUEST", func(): action.emit("fulfill_request", {"uid": npc_uid}); hide())
	W.button(box, "UI_CLOSE", func(): hide())
	show()
