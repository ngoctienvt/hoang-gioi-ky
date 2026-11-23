extends RefCounted

const UITheme = preload("res://ui/theme/ui_theme.gd")


static func t(key: String, fallback: String = "") -> String:
	var translated := TranslationServer.translate(key)
	if translated == key and not fallback.is_empty():
		return fallback
	return translated


static func label(parent: Node, key: String, fallback: String = "") -> Label:
	var node := Label.new()
	node.text = t(key, fallback) if not key.is_empty() else fallback
	parent.add_child(node)
	return node


static func button(parent: Node, key: String, callback: Callable, variation: String = "", fallback: String = "") -> Button:
	var node := Button.new()
	node.text = t(key, fallback) if not key.is_empty() else fallback
	if not variation.is_empty():
		node.theme_type_variation = variation
	node.pressed.connect(func():
		var tree := node.get_tree()
		if tree != null and tree.root != null:
			var am := tree.root.get_node_or_null("AudioManager")
			if am != null:
				am.play_ui("ui_click")
	)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node


static func icon_button(parent: Node, icon_tex: Texture2D, tooltip: String, callback: Callable, min_size: Vector2 = Vector2(36, 36)) -> Button:
	var node := Button.new()
	node.theme_type_variation = &"ButtonIcon"
	node.custom_minimum_size = min_size
	node.tooltip_text = tooltip
	if icon_tex != null:
		node.icon = icon_tex
		node.expand_icon = true
		node.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.add_theme_constant_override("icon_max_width", int(minf(min_size.x, min_size.y) * 0.62))
	node.pressed.connect(func():
		var tree := node.get_tree()
		if tree != null and tree.root != null:
			var am := tree.root.get_node_or_null("AudioManager")
			if am != null:
				am.play_ui("ui_click")
	)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node


static func section_header(parent: Node, title_key: String, fallback: String = "") -> Label:
	var lbl := label(parent, title_key, fallback)
	lbl.theme_type_variation = &"LabelHeading"
	return lbl


static func divider(parent: Node) -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = UITheme.BORDER_GOLD_DIM
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line


static func badge(parent: Node, text_str: String, bg: Color = UITheme.BG_CARD, border: Color = UITheme.BORDER_GOLD_DIM) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_font_size_override("font_size", 12)
	p.add_child(lbl)
	parent.add_child(p)
	return p


static func panel(parent: Node, position: Vector2, size: Vector2, variation: String = "") -> VBoxContainer:
	var panel_node := PanelContainer.new()
	panel_node.position = position
	panel_node.custom_minimum_size = size
	if not variation.is_empty():
		panel_node.theme_type_variation = variation
	parent.add_child(panel_node)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
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
	return UITheme.build_theme()
