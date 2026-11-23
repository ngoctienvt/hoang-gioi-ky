extends VBoxContainer
## Slide-out Crafting & Codex Drawer with custom recipe cards (no redundant category dropdown).

signal action(verb: String, args: Dictionary)
signal close_requested

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")

const GROUP_KEYS := ["UI_TOOLS", "UI_LIGHT", "UI_SURVIVAL", "UI_COMBAT", "UI_BUILDINGS", "UI_TALISMANS", "UI_PUPPETS"]

var wiki := false
var group := 0
var content: VBoxContainer
var header_lbl: Label
var mode_btn: Button
var player: Dictionary = {}
var state: Dictionary = {}
var search := ""


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	add_child(head)

	header_lbl = Label.new()
	header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_lbl.theme_type_variation = &"LabelHeading"
	header_lbl.text = tr(GROUP_KEYS[group])
	head.add_child(header_lbl)

	mode_btn = W.button(head, "UI_WIKI", func():
		wiki = not wiki
		refresh(state, player)
	, "ButtonSubtle")
	mode_btn.add_theme_font_size_override("font_size", 12)

	var close_btn := W.button(head, "", func(): close_requested.emit(), "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.tooltip_text = W.t("UI_CLOSE", "Đóng") + " [Tab]"

	var search_field := LineEdit.new()
	search_field.placeholder_text = tr("UI_SEARCH")
	search_field.clear_button_enabled = true
	search_field.text_changed.connect(func(value):
		search = value
		refresh(state, player)
	)
	add_child(search_field)

	W.divider(self)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(304, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)


func refresh(world: Dictionary, local_player: Dictionary) -> void:
	state = world
	player = local_player
	if header_lbl:
		header_lbl.text = W.t("UI_BOOK", "Thiên Thư") if wiki else tr(GROUP_KEYS[clampi(group, 0, GROUP_KEYS.size() - 1)])
	if mode_btn:
		mode_btn.text = W.t("UI_CRAFT_MODE", "Chế tác") if wiki else tr("UI_WIKI")
	if not content:
		return
	W.clear(content)

	var counts := {}
	for slot in player.get("inventory", {}).get("slots", []):
		if not slot.is_empty():
			counts[slot.id] = counts.get(slot.id, 0) + slot.count
	var tier := nearby_tier(world, local_player)

	for id in RecipeDB.recipes:
		var recipe = RecipeDB.recipes[id]
		if not wiki and int(recipe.group) != group:
			continue
		if not search.is_empty() and not tr(recipe.result.name_key).to_lower().contains(search.to_lower()):
			continue

		var discovered: bool = String(id) in state.get("discovered", [])
		var enough := true
		var reqs := PuppeteerCraft.effective_ingredients(player, recipe)
		for ingredient in reqs:
			if int(counts.get(String(ingredient), 0)) < int(reqs[ingredient]):
				enough = false
				break

		var station_ok := true
		var req_station := str(recipe.get("station") if recipe.get("station") != null else "")
		if not req_station.is_empty():
			station_ok = _has_station(world, local_player, req_station)

		var unlocked := true
		if bool(recipe.get("forbidden_unlock") if recipe.get("forbidden_unlock") != null else false):
			unlocked = String(id) in state.get("forbidden_recipes", []) or discovered

		var tier_ok: bool = recipe.tier <= tier
		var can_craft: bool = enough and tier_ok and station_ok and unlocked

		var card := _build_recipe_card(String(id), recipe, counts, reqs, discovered, can_craft, tier_ok, station_ok, req_station, unlocked)
		content.add_child(card)

	if wiki:
		for property in ["cooking", "alchemy"]:
			W.divider(content)
			W.section_header(content, "UI_" + property.to_upper())
			var entries = RecipeDB.get(property)
			if entries is Array:
				for entry in entries:
					var card := PanelContainer.new()
					card.theme_type_variation = &"PanelCard"
					content.add_child(card)
					var vbox := VBoxContainer.new()
					vbox.add_theme_constant_override("separation", 2)
					card.add_child(vbox)
					var title := Label.new()
					title.text = tr(entry.result.name_key)
					title.add_theme_font_size_override("font_size", 13)
					title.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
					vbox.add_child(title)
					var desc_parts: Array[String] = []
					for field in ["minimum", "maximum", "forbidden", "success"]:
						var value = entry.get(field)
						if value != null:
							desc_parts.append("%s: %s" % [tr("UI_" + field.to_upper()), _condition_text(value)])
					var line := Label.new()
					line.text = "\n".join(desc_parts)
					line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					line.add_theme_font_size_override("font_size", 11)
					line.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
					vbox.add_child(line)


func _build_recipe_card(
	id: String,
	recipe,
	counts: Dictionary,
	reqs: Dictionary,
	discovered: bool,
	can_craft: bool,
	tier_ok: bool,
	station_ok: bool,
	req_station: String,
	unlocked: bool
) -> Control:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not wiki and not can_craft
	btn.custom_minimum_size = Vector2(288, 64)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.095, 0.145, 0.132, 0.94) if can_craft else Color(0.055, 0.078, 0.074, 0.72)
	sb_normal.border_color = UITheme.BORDER_GOLD if can_craft else Color(0.38, 0.33, 0.22, 0.45)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_left = 8
	sb_normal.content_margin_right = 8
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("disabled", sb_normal)

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = UITheme.BG_HOVER
	sb_hover.border_color = UITheme.BORDER_JADE
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.pressed.connect(func():
		action.emit("place_preview" if recipe.is_structure else "craft", {"recipe": id})
	)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	btn.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.custom_minimum_size = Vector2(46, 46)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_sb := StyleBoxFlat.new()
	icon_sb.bg_color = Color(0.04, 0.06, 0.058, 0.9)
	icon_sb.border_color = UITheme.BORDER_GOLD_DIM
	icon_sb.set_border_width_all(1)
	icon_sb.set_corner_radius_all(5)
	icon_sb.content_margin_left = 4
	icon_sb.content_margin_right = 4
	icon_sb.content_margin_top = 4
	icon_sb.content_margin_bottom = 4
	icon_box.add_theme_stylebox_override("panel", icon_sb)
	row.add_child(icon_box)

	var tex := TextureRect.new()
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.texture = recipe.result.icon
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_box.add_child(tex)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(title_row)

	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.text = tr(recipe.result.name_key)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY if can_craft else UITheme.TEXT_MUTED)
	title_row.add_child(name_lbl)

	if discovered:
		var check_lbl := Label.new()
		check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_lbl.text = "✓"
		check_lbl.add_theme_font_size_override("font_size", 12)
		check_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOOD)
		title_row.add_child(check_lbl)

	var req_flow := HFlowContainer.new()
	req_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	req_flow.add_theme_constant_override("h_separation", 8)
	req_flow.add_theme_constant_override("v_separation", 2)
	info.add_child(req_flow)

	for ingredient in reqs:
		var owned := int(counts.get(String(ingredient), 0))
		var needed := int(reqs[ingredient])
		var ing_lbl := Label.new()
		ing_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ing_lbl.text = "%s %d/%d" % [W.item_name(String(ingredient)), owned, needed]
		ing_lbl.add_theme_font_size_override("font_size", 11)
		ing_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOOD if owned >= needed else UITheme.TEXT_BAD)
		req_flow.add_child(ing_lbl)

	if not tier_ok or not station_ok or not unlocked:
		var lock_parts: Array[String] = []
		if not station_ok:
			lock_parts.append(tr("UI_NEED_STATION") + ": " + tr("WORLD_" + req_station.to_upper()))
		if not tier_ok:
			lock_parts.append(tr("UI_TIER_LOCK"))
		if not unlocked:
			lock_parts.append(W.t("UI_FORBIDDEN_LOCK", "Cần lĩnh ngộ"))
		var lock_lbl := Label.new()
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_lbl.text = " • ".join(lock_parts)
		lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.add_theme_color_override("font_color", UITheme.TEXT_WARN)
		info.add_child(lock_lbl)

	return btn


func nearby_tier(world: Dictionary, local_player: Dictionary) -> int:
	var p: Array = local_player.get("position", [0, 0, 0])
	for building in world.get("structures", []):
		if building.kind == "workbench":
			var at: Array = building.position
			if Vector2(p[0], p[2]).distance_to(Vector2(at[0], at[2])) <= 5:
				return 1
	return 0


func _has_station(world: Dictionary, local_player: Dictionary, station_kind: String) -> bool:
	var p: Array = local_player.get("position", [0, 0, 0])
	for building in world.get("structures", []):
		if building.kind == station_kind:
			var at: Array = building.position
			if Vector2(p[0], p[2]).distance_to(Vector2(at[0], at[2])) <= 5.0:
				return true
	return false


func nearby_stations(world: Dictionary, local_player: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var p: Array = local_player.get("position", [0, 0, 0])
	for building in world.get("structures", []):
		var kind := str(building.get("kind", ""))
		if kind.is_empty() or kind in result:
			continue
		var at: Array = building.get("position", [0, 0, 0])
		if Vector2(p[0], p[2]).distance_to(Vector2(at[0], at[2])) <= 5.0:
			result.append(kind)
	result.sort()
	return result


func _condition_text(value: Variant) -> String:
	var parts: Array[String] = []
	if value is Dictionary:
		for key in value:
			parts.append(tr("TAG_" + String(key).to_upper()) + " " + str(value[key]))
	elif value is Array:
		for key in value:
			parts.append(tr("TAG_" + String(key).to_upper()))
	else:
		return str(value)
	return " / ".join(parts) if not parts.is_empty() else tr("UI_NONE")
