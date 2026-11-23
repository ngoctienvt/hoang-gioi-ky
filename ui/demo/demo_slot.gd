extends Button

signal action(verb: String, args: Dictionary)
signal selected(slot: int)
const W = preload("res://ui/demo/demo_widgets.gd")
var index := 0
var stack: Dictionary = {}

func configure(slot: int, value: Dictionary) -> void:
	index = slot
	stack = value
	custom_minimum_size = Vector2(70, 65)
	var id := String(stack.get("id", ""))
	text = "%d\n%s" % [slot + 1, W.item_name(id) if not id.is_empty() else tr("DEMO_EMPTY")]
	if not id.is_empty():
		text += " ×%d" % stack.get("count", 1)
		var item = ItemDB.get_item(id)
		if item and item.icon: icon = item.icon
		if item and item.max_durability > 0:
			text += "\n%d%%" % int(100.0 * stack.get("durability", item.max_durability) / item.max_durability)
	tooltip_text = text + "\n" + tr("DEMO_SLOT_HINT")
	add_theme_font_size_override("font_size", 12)
	gui_input.connect(_input_slot)

func _input_slot(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed: return
	if event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(index)
		if event.shift_pressed:
			action.emit("drop", {"slot": index, "count": stack.get("count", 1)})
	if event.button_index == MOUSE_BUTTON_RIGHT and not stack.is_empty():
		var item = ItemDB.get_item(String(stack.get("id", "")))
		action.emit("equip" if item and item.category in [ItemDef.Category.TOOL, ItemDef.Category.WEAPON] else "use", {"slot": index})
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack.is_empty(): return null
	var preview := Label.new()
	preview.text = text
	set_drag_preview(preview)
	return {"slot": index, "split": Input.is_key_pressed(KEY_CTRL), "count": maxi(1, int(stack.get("count", 1)) / 2)}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot") and data.slot != index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	action.emit("split" if data.split else "move_slot", {"from": data.slot, "to": index, "count": data.count})
