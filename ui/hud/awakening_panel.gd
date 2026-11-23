extends PanelContainer
## Awakening & Skill Tree modal with 3-tier layout (left) and 3 Imprint slots (right).

signal action(verb: String, args: Dictionary)
signal close_requested

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")
const WorldSkills = preload("res://world/simulation/world_skills.gd")

var content: VBoxContainer
var selected_slot := 0


func _ready() -> void:
	theme_type_variation = &"PanelModal"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(700, 490)
	offset_left = -350
	offset_right = 350
	offset_top = -245
	offset_bottom = 245

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	hide()


func refresh(state: Dictionary, player: Dictionary, slot_idx: int) -> void:
	selected_slot = slot_idx
	if not visible or player.is_empty():
		return
	W.clear(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title := W.label(header, "UI_AWAKENING_TITLE")
	title.theme_type_variation = &"LabelTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tier := int(player.get("awakening_tier", 0))
	var pts := int(player.get("skill_points", 0))
	W.badge(header, tr("UI_AWAKENING_TIER") % [tier, pts], Color(0.11, 0.17, 0.15, 0.95), UITheme.BORDER_GOLD if pts > 0 else UITheme.BORDER_GOLD_DIM)

	var close_btn := W.button(header, "", func(): close_requested.emit(); hide(), "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(30, 30)

	for r in state.get("rituals", []):
		if int(r.get("owner_uid", 0)) == int(player.get("uid", -1)):
			var r_card := PanelContainer.new()
			r_card.theme_type_variation = &"PanelCard"
			content.add_child(r_card)
			var rl := Label.new()
			rl.text = tr("UI_RITUAL_PROGRESS") % [int(r.get("wave", 1)), 3, ceili(float(r.get("wave_timer", 0.0)))]
			rl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
			r_card.add_child(rl)

	W.divider(content)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	content.add_child(columns)

	# Left column: Skill Tree grouped by Tier
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.65
	left_col.add_theme_constant_override("separation", 8)
	columns.add_child(left_col)

	W.section_header(left_col, "UI_SKILL_TREE")
	var tree_scroll := ScrollContainer.new()
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(tree_scroll)

	var tree_box := VBoxContainer.new()
	tree_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_box.add_theme_constant_override("separation", 8)
	tree_scroll.add_child(tree_box)

	var cdef = WorldAbilities.character_def(player)
	if cdef != null:
		var unlocked: Array = player.get("skills", [])
		var nodes := WorldSkills.skills_for_tree(String(cdef.skill_tree_id))
		for t_level in [1, 2, 3]:
			var tier_nodes: Array = []
			for s in nodes:
				if int(s.tier) == t_level:
					tier_nodes.append(s)
			if tier_nodes.is_empty():
				continue
			var t_lbl := Label.new()
			t_lbl.text = "— Tầng %d —" % t_level
			t_lbl.add_theme_font_size_override("font_size", 12)
			t_lbl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT if tier >= t_level else UITheme.TEXT_MUTED)
			tree_box.add_child(t_lbl)

			for s in tier_nodes:
				var sid := String(s.id)
				var is_unlocked := sid in unlocked
				var excluded := false
				for ex in s.excludes:
					if String(ex) in unlocked:
						excluded = true
						break
				var card := PanelContainer.new()
				card.theme_type_variation = &"PanelCard"
				tree_box.add_child(card)
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 10)
				card.add_child(row)

				var txt_box := VBoxContainer.new()
				txt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				txt_box.add_theme_constant_override("separation", 2)
				row.add_child(txt_box)

				var s_title := Label.new()
				s_title.text = tr(s.name_key)
				s_title.add_theme_font_size_override("font_size", 13)
				s_title.add_theme_color_override("font_color", UITheme.TEXT_GOOD if is_unlocked else (UITheme.TEXT_MUTED if excluded else UITheme.TEXT_PRIMARY))
				txt_box.add_child(s_title)

				var s_desc := Label.new()
				s_desc.text = tr(s.desc_key)
				s_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				s_desc.add_theme_font_size_override("font_size", 11)
				s_desc.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
				txt_box.add_child(s_desc)

				var b := Button.new()
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				if is_unlocked:
					b.text = tr("UI_UNLOCKED")
					b.disabled = true
				elif excluded:
					b.text = tr("UI_EXCLUDED")
					b.disabled = true
				else:
					b.text = tr("UI_UNLOCK")
					b.theme_type_variation = &"ButtonPrimary"
					b.disabled = pts < 1 or tier < int(s.tier)
					b.pressed.connect(func(): action.emit("unlock_skill", {"skill_id": sid}))
				row.add_child(b)

	# Right column: 3 Imprint Slots
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	columns.add_child(right_col)

	var max_imp := mini(3, tier)
	var imprints: Array = player.get("imprints", [])
	W.section_header(right_col, "UI_IMPRINTS")
	var imp_info := Label.new()
	imp_info.text = tr("UI_IMPRINT_SLOTS") % [imprints.size(), max_imp]
	imp_info.add_theme_font_size_override("font_size", 12)
	imp_info.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	right_col.add_child(imp_info)

	for i in 3:
		var slot_card := PanelContainer.new()
		slot_card.theme_type_variation = &"PanelCard"
		right_col.add_child(slot_card)
		var row := HBoxContainer.new()
		slot_card.add_child(row)
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i < imprints.size():
			var imp_id := str(imprints[i])
			lbl.text = tr("ITEM_" + imp_id.to_upper())
			lbl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
			row.add_child(lbl)
			var idx := i
			W.button(row, "UI_UNEQUIP_IMPRINT", func(): action.emit("unequip_imprint", {"index": idx}), "ButtonSubtle")
		elif i < max_imp:
			lbl.text = "Ô %d · Trống" % (i + 1)
			lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			row.add_child(lbl)
		else:
			lbl.text = "Ô %d · Khóa (Tầng %d)" % [i + 1, i + 1]
			lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45, 0.55))
			row.add_child(lbl)

	if imprints.size() < max_imp:
		var eq_btn := W.button(right_col, "UI_EQUIP_IMPRINT", func(): action.emit("equip_imprint", {"slot": selected_slot}), "ButtonPrimary")
		eq_btn.custom_minimum_size.y = 36
