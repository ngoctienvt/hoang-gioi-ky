extends RefCounted


static func is_discounted_recipe(recipe_def) -> bool:
	if recipe_def == null:
		return false
	if int(recipe_def.group) in [RecipeDef.Group.TALISMANS, RecipeDef.Group.PUPPETS]:
		return true
	var rid := String(recipe_def.id)
	return "array" in rid or "puppet" in rid or "talisman" in rid


static func effective_ingredients(player: Dictionary, recipe_def) -> Dictionary:
	if recipe_def == null:
		return {}
	if str(player.get("character", "")) != "puppeteer" or not is_discounted_recipe(recipe_def):
		return recipe_def.ingredients
	var out: Dictionary = {}
	for key in recipe_def.ingredients:
		out[key] = maxi(1, int(recipe_def.ingredients[key]) - 1)
	return out


static func talisman_success_chance(player: Dictionary, base_chance: float = 0.85) -> float:
	var bonus := 0.15 if str(player.get("character", "")) == "puppeteer" else 0.0
	return clampf(base_chance + bonus, 0.0, 1.0)


static func guard_puppets(world, owner_peer: int) -> Array:
	var out: Array = []
	for p in world.state.get("puppets", []):
		if str(p.get("task", "")) == "guard" and int(p.get("owner_peer", 0)) == owner_peer and float(p.get("health", 0.0)) > 0.0:
			out.append(p)
	return out
