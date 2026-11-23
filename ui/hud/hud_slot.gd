extends Button

signal action(verb: String, args: Dictionary)
signal selected(slot: int)
const W = preload("res://ui/hud/hud_widgets.gd")
var index := 0
var stack: Dictionary = {}
var item_texture: Texture2D
var is_selected := false:
	set(value):
		is_selected = value
		queue_redraw()

func configure(slot: int, value: Dictionary) -> void:
	index = slot
	stack = value
	custom_minimum_size = Vector2(58, 54)
	var id := String(stack.get("id", ""))
	var description := "%d · %s" % [slot + 1, W.item_name(id) if not id.is_empty() else tr("UI_EMPTY")]
	if not id.is_empty():
		description += " ×%d" % stack.get("count", 1)
		var item = ItemDB.get_item(id)
		if item and item.icon: item_texture = item.icon
		if item and item.max_durability > 0:
			description += "\n%d%%" % int(100.0 * stack.get("durability", item.max_durability) / item.max_durability)
		elif item and item.spoil_time > 0.0:
			description += "\n%d%%" % int(100.0 * float(stack.get("freshness", 1.0)))
	text = ""
	tooltip_text = description + "\n" + tr("UI_SLOT_HINT")
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
		var is_equip: bool = item != null and (item.category in [ItemDef.Category.TOOL, ItemDef.Category.WEAPON] or not item.equipment_slot.is_empty())
		action.emit("equip" if is_equip else "use", {"slot": index})
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack.is_empty(): return null
	var preview := Label.new()
	preview.text = W.item_name(String(stack.get("id", "")))
	set_drag_preview(preview)
	return {"slot": index, "split": Input.is_key_pressed(KEY_CTRL), "count": maxi(1, int(stack.get("count", 1)) / 2)}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot") and data.slot != index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	action.emit("split" if data.split else "move_slot", {"from": data.slot, "to": index, "count": data.count})

func _draw() -> void:
	if is_selected:
		draw_style_box(get_theme_stylebox("focus"), Rect2(Vector2.ZERO, size))
	var font := get_theme_font("font")
	draw_string(font, Vector2(4, 13), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c6b88c"))
	if item_texture:
		draw_texture_rect(item_texture, Rect2((size.x - 36) * 0.5, 4, 36, 36), false)
	if stack.is_empty(): return
	var count_text := str(stack.get("count", 1))
	var count_at := Vector2(size.x - font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x - 4, size.y - 8)
	draw_string_outline(font, count_at, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color("17201b"))
	draw_string(font, count_at, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f5e8c7"))
	var item = ItemDB.get_item(String(stack.get("id", "")))
	if item and item.max_durability > 0:
		var fraction := clampf(float(stack.get("durability", item.max_durability)) / item.max_durability, 0, 1)
		draw_rect(Rect2(5, size.y - 4, size.x - 10, 3), Color("514638"))
		draw_rect(Rect2(5, size.y - 4, (size.x - 10) * fraction, 3), Color("b79c52") if fraction > 0.25 else Color("b64e42"))
	elif item and item.spoil_time > 0:
		var freshness := clampf(float(stack.get("freshness", 1.0)), 0, 1)
		draw_rect(Rect2(5, size.y - 4, size.x - 10, 3), Color("514638"))
		draw_rect(Rect2(5, size.y - 4, (size.x - 10) * freshness, 3), Color("86ad79") if freshness > 0.25 else Color("b64e42"))
