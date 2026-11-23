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
	return TranslationServer.translate(item.name_key) if item else TranslationServer.translate("UI_EMPTY")

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
		if state == "pressed":
			button_style.bg_color = Color("304b40")
			button_style.border_color = Color("97c4a9")
		if state == "disabled": button_style.bg_color = Color("25292a")
		result.set_stylebox(state, "Button", button_style)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color.TRANSPARENT
	focus_style.border_color = Color("b3d9bc")
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	result.set_stylebox("focus", "Button", focus_style)
	result.set_color("font_color", "Button", Color("eee0ba"))
	result.set_color("font_disabled_color", "Button", Color("a39f8b"))
	result.set_color("font_color", "Label", Color("eee0ba"))
	return result

