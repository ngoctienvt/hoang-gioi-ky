extends Node
const RECIPES_DIR = "res://data/recipes/"
var recipes: Dictionary = {}
var cooking: Array[TagRecipeDef] = []
var alchemy: Array[TagRecipeDef] = []

func _ready() -> void:
	reload_data()

func reload_data() -> void:
	recipes.clear()
	cooking.clear()
	alchemy.clear()
	# Keep resource discovery compatible with exported .tres remaps.
	for file in ResourceLoader.list_directory(RECIPES_DIR):
		if file.ends_with(".tres"):
			var recipe = load(RECIPES_DIR + file) as RecipeDef
			if recipe != null:
				recipes[String(recipe.id)] = recipe
	for kind in ["cooking", "alchemy"]:
		for file in ResourceLoader.list_directory("res://data/" + kind):
			if file.ends_with(".tres"):
				var recipe = load("res://data/" + kind + "/" + file) as TagRecipeDef
				if recipe != null:
					if kind == "cooking":
						cooking.append(recipe)
					else:
						alchemy.append(recipe)
	print("[RecipeDB] Loaded %d crafts, %d meals, %d pills" % [recipes.size(), cooking.size(), alchemy.size()])

func match_recipe(ids: Array, kind: String, roll: float = 0.0) -> Dictionary:
	if ids.size() != 4 or not kind in ["cooking", "alchemy"]:
		return {}
	var tags: Dictionary = {}
	for id in ids:
		if not id is String:
			return {}
		var item = ItemDB.get_item(id)
		if item == null:
			return {}
		for tag in item.tags:
			tags[tag] = float(tags.get(tag, 0.0)) + item.tags[tag]
	var candidates: Array[TagRecipeDef] = []
	var priority = -2147483648
	var pool = alchemy if kind == "alchemy" else cooking
	for recipe in pool:
		if recipe.matches(tags):
			if recipe.priority > priority:
				candidates.clear()
				priority = recipe.priority
			if recipe.priority == priority:
				candidates.append(recipe)
	var fallback = "waste_pill" if kind == "alchemy" else "charred_food"
	if candidates.is_empty():
		return {"id": fallback, "result": fallback, "time": 10.0, "success": false, "chance": 0.0}
	var weight = 0.0
	for recipe in candidates:
		weight += maxf(0.0, recipe.weight)
	var cursor = clampf(roll, 0.0, 0.999999) * weight
	var selected = candidates.back()
	for recipe in candidates:
		cursor -= maxf(0.0, recipe.weight)
		if cursor < 0.0:
			selected = recipe
			break
	return {"id": selected.id, "result": String(selected.result.id), "time": selected.time, "success": true, "chance": selected.success}

func alchemy_chance(recipe_id: String, furnace_tier: int = 0, solvent: String = "") -> float:
	for recipe in alchemy:
		if recipe.id == recipe_id:
			var bonus = 0.0
			var item = ItemDB.get_item(solvent)
			if item != null and item.get_tag(recipe.solvent_tag) > 0.0:
				bonus = 0.15
			return clampf(recipe.success + clampi(furnace_tier, 0, 3) * 0.05 + bonus, 0.0, 1.0)
	return 0.0

func resolve_alchemy(ids: Array, roll: float, furnace_tier: int = 0, solvent: String = "") -> Dictionary:
	var output = match_recipe(ids, "alchemy")
	if output.is_empty():
		return {}
	var chance = alchemy_chance(output.id, furnace_tier, solvent)
	output.chance = chance
	output.success = clampf(roll, 0.0, 1.0) < chance
	if not output.success:
		output.result = "waste_pill"
	return output
