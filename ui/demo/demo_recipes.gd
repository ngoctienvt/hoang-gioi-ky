extends VBoxContainer

signal action(verb: String, args: Dictionary)
const W = preload("res://ui/demo/demo_widgets.gd")
var wiki := false
var group := 0
var content: VBoxContainer
var player: Dictionary = {}
var state: Dictionary = {}
var search := ""

func _ready() -> void:
	W.button(self, "DEMO_WIKI", func(): wiki = not wiki; refresh(state, player))
	var tabs := OptionButton.new()
	for key in ["DEMO_TOOLS", "DEMO_LIGHT", "DEMO_SURVIVAL", "DEMO_COMBAT", "DEMO_BUILDINGS"]:
		tabs.add_item(tr(key))
	tabs.item_selected.connect(func(value): group = value; refresh(state, player))
	add_child(tabs)
	var search_field := LineEdit.new()
	search_field.placeholder_text = tr("DEMO_SEARCH")
	search_field.text_changed.connect(func(value): search = value; refresh(state, player))
	add_child(search_field)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(252, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

func refresh(world: Dictionary, local_player: Dictionary) -> void:
	state = world
	player = local_player
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
		for ingredient in recipe.ingredients:
			var owned := int(counts.get(String(ingredient), 0))
			var needed := int(recipe.ingredients[ingredient])
			enough = enough and owned >= needed
			text += "\n%s %d/%d" % [W.item_name(String(ingredient)), owned, needed]
		if recipe.tier > tier: text += "\n" + tr("DEMO_TIER_LOCK")
		var button := Button.new()
		button.text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.disabled = not wiki and (not enough or recipe.tier > tier)
		button.pressed.connect(func(): action.emit("place_preview" if recipe.is_structure else "craft", {"recipe": String(id)}))
		content.add_child(button)
	if wiki:
		for property in ["cooking", "alchemy"]:
			W.label(content, "DEMO_" + property.to_upper())
			var entries = RecipeDB.get(property)
			if entries is Array:
				for entry in entries:
					var description: String = tr(entry.result.name_key)
					for field in ["minimum", "maximum", "forbidden", "success"]:
						var value = entry.get(field)
						if value != null: description += "\n%s: %s" % [tr("DEMO_" + field.to_upper()), str(value)]
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

