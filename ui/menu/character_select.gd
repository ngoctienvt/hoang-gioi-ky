extends PanelContainer

signal character_chosen(char_id: String)

const W = preload("res://ui/hud/hud_widgets.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(680, 440)
	position = Vector2(-340, -220)
	var box := VBoxContainer.new()
	add_child(box)
	var title := W.label(box, "UI_SELECT_CHARACTER")
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for cdef in WorldAbilities.selectable_characters():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(316, 175)
		grid.add_child(card)
		var card_box := VBoxContainer.new()
		card.add_child(card_box)
		var header := HBoxContainer.new()
		card_box.add_child(header)
		var swatch := ColorRect.new()
		swatch.color = cdef.body_color
		swatch.custom_minimum_size = Vector2(18, 18)
		header.add_child(swatch)
		var name_lbl := W.label(header, cdef.name_key)
		name_lbl.add_theme_font_size_override("font_size", 16)
		var power_lbl := W.label(card_box, cdef.power_key)
		power_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		power_lbl.add_theme_font_size_override("font_size", 12)
		var cost_lbl := W.label(card_box, cdef.cost_key)
		cost_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cost_lbl.add_theme_font_size_override("font_size", 12)
		cost_lbl.add_theme_color_override("font_color", Color("e69d85"))
		var cid := String(cdef.id)
		W.button(card_box, "UI_CHOOSE_CHARACTER", func(): character_chosen.emit(cid))
