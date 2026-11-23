extends VBoxContainer

signal action(verb: String, args: Dictionary)
const W = preload("res://ui/hud/hud_widgets.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")
var wiki := false
var group := 0
var content: VBoxContainer
var tabs: OptionButton
var player: Dictionary = {}
var state: Dictionary = {}
var search := ""

func _ready() -> void:
	W.button(self, "UI_WIKI", func(): wiki = not wiki; refresh(state, player))
	tabs = OptionButton.new()
	for key in ["UI_TOOLS", "UI_LIGHT", "UI_SURVIVAL", "UI_COMBAT", "UI_BUILDINGS", "UI_TALISMANS", "UI_PUPPETS"]:
		tabs.add_item(tr(key))
	tabs.item_selected.connect(func(value): group = value; refresh(state, player))
	add_child(tabs)
	var search_field := LineEdit.new()
	search_field.placeholder_text = tr("UI_SEARCH")
	search_field.text_changed.connect(func(value): search = value; refresh(state, player))
	add_child(search_field)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(252, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

func refresh(world: Dictionary, local_player: Dictionary) -> void:
	state = world
	player = local_player
	if tabs and tabs.selected != group:
		tabs.select(group)
	if not content: return
	W.clear(content)
	var counts := {}
	for slot in player.get("inventory", {}).get("slots", []):
		if not slot.is_empty(): counts[slot.id] = counts.get(slot.id, 0) + slot.count
	var tier := nearby_tier(world, local_player)
	for id in RecipeDB.recipes:
		var recipe = RecipeDB.recipes[id]
		if not wiki and int(recipe.group) != group: continue
		if not search.is_empty() and not tr(recipe.result.name_key).to_lower().contains(search.to_lower()): continue
		var text: String = tr(recipe.result.name_key)
		if String(id) in state.get("discovered", []): text = "✓ " + text
		var enough := true
		var reqs := PuppeteerCraft.effective_ingredients(player, recipe)
		for ingredient in reqs:
			var owned := int(counts.get(String(ingredient), 0))
			var needed := int(reqs[ingredient])
			enough = enough and owned >= needed
			text += "\n%s %d/%d" % [W.item_name(String(ingredient)), owned, needed]
		var station_ok := true
		var req_station := str(recipe.get("station") if recipe.get("station") != null else "")
		if not req_station.is_empty():
			station_ok = _has_station(world, local_player, req_station)
			if not station_ok:
				text += "\n" + tr("UI_NEED_STATION") + ": " + tr("WORLD_" + req_station.to_upper())
		var unlocked := true
		if bool(recipe.get("forbidden_unlock") if recipe.get("forbidden_unlock") != null else false):
			unlocked = String(id) in state.get("forbidden_recipes", []) or String(id) in state.get("discovered", [])
		if recipe.tier > tier: text += "\n" + tr("UI_TIER_LOCK")
		var button := Button.new()
		button.text = text
		button.icon = recipe.result.icon
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)
		button.clip_text = true
		button.tooltip_text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.disabled = not wiki and (not enough or recipe.tier > tier or not station_ok or not unlocked)
		button.pressed.connect(func(): action.emit("place_preview" if recipe.is_structure else "craft", {"recipe": String(id)}))
		content.add_child(button)
	if wiki:
		for property in ["cooking", "alchemy"]:
			W.label(content, "UI_" + property.to_upper())
			var entries = RecipeDB.get(property)
			if entries is Array:
				for entry in entries:
					var description: String = tr(entry.result.name_key)
					for field in ["minimum", "maximum", "forbidden", "success"]:
						var value = entry.get(field)
						if value != null: description += "\n%s: %s" % [tr("UI_" + field.to_upper()), _condition_text(value)]
					var line := Label.new()
					line.text = description
					line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					line.custom_minimum_size.x = 245
					content.add_child(line)

func nearby_tier(world: Dictionary, local_player: Dictionary) -> int:
	var p: Array = local_player.get("position", [0, 0, 0])
	for building in world.get("structures", []):
		if building.kind == "workbench":
			var at: Array = building.position
			if Vector2(p[0], p[2]).distance_to(Vector2(at[0], at[2])) <= 5: return 1
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
		for key in value: parts.append(tr("TAG_" + String(key).to_upper()) + " " + str(value[key]))
	elif value is Array:
		for key in value: parts.append(tr("TAG_" + String(key).to_upper()))
	else: return str(value)
	return " / ".join(parts) if not parts.is_empty() else tr("UI_NONE")

