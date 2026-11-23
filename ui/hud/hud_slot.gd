extends Button

signal action(verb: String, args: Dictionary)
signal selected(slot: int)

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

var index := 0
var stack: Dictionary = {}
var item_texture: Texture2D
var _hovered := false
var is_selected := false:
	set(value):
		is_selected = value
		queue_redraw()


func configure(slot: int, value: Dictionary) -> void:
	index = slot
	stack = value
	item_texture = null
	custom_minimum_size = Vector2(48, 48)
	focus_mode = Control.FOCUS_NONE
	var id := String(stack.get("id", ""))
	var description := "%d · %s" % [slot + 1, W.item_name(id) if not id.is_empty() else tr("UI_EMPTY")]
	if not id.is_empty():
		description += " ×%d" % stack.get("count", 1)
		var item = ItemDB.get_item(id)
		if item and item.icon:
			item_texture = item.icon
		if item and item.max_durability > 0:
			description += "\n%d%%" % int(100.0 * stack.get("durability", item.max_durability) / item.max_durability)
		elif item and item.spoil_time > 0.0:
			description += "\n%d%%" % int(100.0 * float(stack.get("freshness", 1.0)))
	text = ""
	tooltip_text = description + "\n" + tr("UI_SLOT_HINT")
	if not gui_input.is_connected(_input_slot):
		gui_input.connect(_input_slot)
	if not mouse_entered.is_connected(_on_hover_in):
		mouse_entered.connect(_on_hover_in)
		mouse_exited.connect(_on_hover_out)
	queue_redraw()


func _on_hover_in() -> void:
	_hovered = true
	queue_redraw()


func _on_hover_out() -> void:
	_hovered = false
	queue_redraw()


func _input_slot(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(index)
		if event.shift_pressed and not stack.is_empty():
			action.emit("drop", {"slot": index, "count": stack.get("count", 1)})
	if event.button_index == MOUSE_BUTTON_RIGHT and not stack.is_empty():
		var item = ItemDB.get_item(String(stack.get("id", "")))
		var is_equip: bool = item != null and (item.category in [ItemDef.Category.TOOL, ItemDef.Category.WEAPON] or not item.equipment_slot.is_empty())
		action.emit("equip" if is_equip else "use", {"slot": index})
		accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack.is_empty():
		return null
	var preview := HBoxContainer.new()
	if item_texture != null:
		var tex := TextureRect.new()
		tex.texture = item_texture
		tex.custom_minimum_size = Vector2(28, 28)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(tex)
	var lbl := Label.new()
	lbl.text = W.item_name(String(stack.get("id", "")))
	preview.add_child(lbl)
	set_drag_preview(preview)
	return {"slot": index, "split": Input.is_key_pressed(KEY_CTRL), "count": maxi(1, int(stack.get("count", 1)) / 2)}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot") and data.slot != index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	action.emit("split" if data.split else "move_slot", {"from": data.slot, "to": index, "count": data.count})


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var bg := Color(0.11, 0.16, 0.145, 0.96) if is_selected else (Color(0.10, 0.14, 0.13, 0.95) if _hovered else Color(0.065, 0.095, 0.088, 0.92))
	draw_rect(rect, bg, true)
	var border := UITheme.TEXT_ACCENT if is_selected else (UITheme.BORDER_GOLD if _hovered else UITheme.BORDER_GOLD_DIM)
	draw_rect(rect, border, false, 2.0 if is_selected else 1.0)

	var font := get_theme_font("font")
	var key_txt := "0" if index == 9 else str(index + 1)
	draw_string(font, Vector2(4, 12), key_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UITheme.TEXT_ACCENT if is_selected else UITheme.TEXT_MUTED)

	if item_texture:
		draw_texture_rect(item_texture, Rect2((size.x - 30.0) * 0.5, 5.0, 30.0, 30.0), false)
	if stack.is_empty():
		return

	var count_val := int(stack.get("count", 1))
	if count_val > 1:
		var count_text := str(count_val)
		var count_w := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var count_at := Vector2(size.x - count_w - 4.0, size.y - 7.0)
		draw_string_outline(font, count_at, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color("101815"))
		draw_string(font, count_at, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UITheme.TEXT_PRIMARY)

	var item = ItemDB.get_item(String(stack.get("id", "")))
	if item and item.max_durability > 0:
		var fraction := clampf(float(stack.get("durability", item.max_durability)) / item.max_durability, 0.0, 1.0)
		draw_rect(Rect2(4, size.y - 4, size.x - 8, 2.5), Color("2b261e"))
		draw_rect(Rect2(4, size.y - 4, (size.x - 8) * fraction, 2.5), Color("c7a454") if fraction > 0.25 else UITheme.BORDER_DANGER)
	elif item and item.spoil_time > 0.0:
		var freshness := clampf(float(stack.get("freshness", 1.0)), 0.0, 1.0)
		draw_rect(Rect2(4, size.y - 4, size.x - 8, 2.5), Color("2b261e"))
		draw_rect(Rect2(4, size.y - 4, (size.x - 8) * freshness, 2.5), Color("7ec289") if freshness > 0.25 else UITheme.BORDER_DANGER)
