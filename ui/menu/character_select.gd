extends PanelContainer
## Character Selection modal with portrait hook (auto-loads portrait-<id>.png when available) + styled emblem fallback.

signal character_chosen(char_id: String)

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(780, 490)
	offset_left = -390
	offset_right = 390
	offset_top = -245
	offset_bottom = 245

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := W.label(box, "UI_SELECT_CHARACTER")
	title.theme_type_variation = &"LabelTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	W.divider(box)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)

	for cdef in WorldAbilities.selectable_characters():
		var card := PanelContainer.new()
		card.theme_type_variation = &"PanelCard"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)

		var outer := VBoxContainer.new()
		outer.add_theme_constant_override("separation", 8)
		card.add_child(outer)

		var top := HBoxContainer.new()
		top.size_flags_vertical = Control.SIZE_EXPAND_FILL
		top.add_theme_constant_override("separation", 12)
		outer.add_child(top)

		top.add_child(_build_portrait(String(cdef.id), tr(cdef.name_key), cdef.body_color))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 4)
		top.add_child(info)

		var name_lbl := W.label(info, cdef.name_key)
		name_lbl.theme_type_variation = &"LabelHeading"

		var ab_row := HFlowContainer.new()
		ab_row.add_theme_constant_override("h_separation", 6)
		ab_row.add_theme_constant_override("v_separation", 4)
		info.add_child(ab_row)
		var keys := ["Q", "E", "R"]
		for i in cdef.abilities.size():
			var adef: AbilityDef = cdef.abilities[i]
			var k: String = keys[i] if i < keys.size() else ""
			W.badge(ab_row, "[%s] %s" % [k, tr(adef.name_key)], Color(0.05, 0.08, 0.075, 0.9), UITheme.BORDER_GOLD_DIM)

		var power_lbl := W.label(info, cdef.power_key)
		power_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		power_lbl.add_theme_font_size_override("font_size", 12)
		power_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOOD)

		var cost_lbl := W.label(info, cdef.cost_key)
		cost_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cost_lbl.add_theme_font_size_override("font_size", 12)
		cost_lbl.add_theme_color_override("font_color", UITheme.TEXT_BAD)

		var cid := String(cdef.id)
		var btn := W.button(outer, "UI_CHOOSE_CHARACTER", func(): character_chosen.emit(cid), "ButtonPrimary")
		btn.custom_minimum_size.y = 34


func _build_portrait(cid: String, char_name: String, col: Color) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(78, 98)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.65)
	sb.border_color = UITheme.BORDER_GOLD
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	frame.add_theme_stylebox_override("panel", sb)

	var candidates := [
		"res://assets/ui/illustrations/portrait-%s.png" % cid,
		"res://assets/ui/illustrations/portrait-%s.png" % cid.replace("_", "-"),
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var tex := load(path)
			if tex is Texture2D:
				var tr_node := TextureRect.new()
				tr_node.texture = tex
				tr_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				frame.add_child(tr_node)
				return frame

	var crest := Label.new()
	crest.text = char_name.left(1).to_upper()
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crest.add_theme_font_size_override("font_size", 32)
	crest.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	frame.add_child(crest)
	return frame
