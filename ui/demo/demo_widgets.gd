extends RefCounted

static func label(parent: Node, key: String) -> Label:
	var node := Label.new()
	node.text = TranslationServer.translate(key)
	parent.add_child(node)
	return node

static func button(parent: Node, key: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = TranslationServer.translate(key)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

static func panel(parent: Node, position: Vector2, size: Vector2) -> VBoxContainer:
	var panel_node := PanelContainer.new()
	panel_node.position = position
	panel_node.custom_minimum_size = size
	parent.add_child(panel_node)
	var box := VBoxContainer.new()
	panel_node.add_child(box)
	return box

static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

static func item_name(id: String) -> String:
	var item = ItemDB.get_item(id)
	return TranslationServer.translate(item.name_key) if item else TranslationServer.translate("DEMO_EMPTY")

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.075, 0.94)
	style.border_color = Color("a18348")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	result.set_stylebox("panel", "PanelContainer", style)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var button_style := style.duplicate()
		if state == "hover": button_style.bg_color = Color("40514b")
		if state == "disabled": button_style.bg_color = Color("25292a")
		result.set_stylebox(state, "Button", button_style)
	result.set_color("font_color", "Label", Color("eee0ba"))
	return result

