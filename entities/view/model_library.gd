extends RefCounted

const PLAYER_DEFAULT := "res://assets/models/characters/char_ancient_beast_blood/char_ancient_beast_blood.glb"

const PLAYER_MODELS := {
	"beast_bloodline": PLAYER_DEFAULT,
}

const CREATURE_MODELS := {
	"wolf": "res://assets/models/creatures/creature_forest_wolf/creature_forest_wolf.glb",
	"ice_wolf": "res://assets/models/creatures/creature_forest_wolf/creature_forest_wolf.glb",
	"rabbit": "res://assets/models/creatures/creature_spirit_rabbit/creature_spirit_rabbit.glb",
	"spirit_rabbit": "res://assets/models/creatures/creature_spirit_rabbit/creature_spirit_rabbit.glb",
	"monkey": "res://assets/models/creatures/creature_spirit_monkey/creature_spirit_monkey.glb",
	"spirit_monkey": "res://assets/models/creatures/creature_spirit_monkey/creature_spirit_monkey.glb",
}

const NODE_MODELS := {
	"tree": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"pine_tree": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"ancient_pine": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"ancient_fruit_tree": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"snow_pine": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"charred_tree": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"rotten_tree": "res://assets/models/nature/tree_common_a/tree_common_a_standing.glb",
	"berry_bush": "res://assets/models/nature/bush_berry/bush_berry_ripe.glb",
	"fruit_bush": "res://assets/models/nature/bush_berry/bush_berry_ripe.glb",
	"fire_berry_bush": "res://assets/models/nature/bush_berry/bush_berry_ripe.glb",
	"twig_bush": "res://assets/models/nature/bush_twig/bush_twig_full.glb",
	"twigs": "res://assets/models/nature/bush_twig/bush_twig_full.glb",
	"herb": "res://assets/models/nature/herb_spirit_wild/herb_spirit_wild.glb",
	"soul_herb_node": "res://assets/models/nature/herb_spirit_wild/herb_spirit_wild.glb",
	"thunder_herb": "res://assets/models/nature/herb_spirit_wild/herb_spirit_wild.glb",
	"rock": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"spirit_rock": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"moss_rock": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"quartz_rock": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"basalt_rock": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"cinnabar_ore": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"dark_iron_vein": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"eternal_ice_vein": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"magma_ore": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"thunder_crystal_vein": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"ice_boulder": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"sect_ore": "res://assets/models/nature/rock_spirit_ore/rock_spirit_ore_stage1.glb",
	"spring": "res://assets/models/nature/spring_thanh_moc/spring_thanh_moc.glb",
	"rabbit_den": "res://assets/models/nature/den_rabbit_burrow/den_rabbit_burrow.glb",
	"wolf_den": "res://assets/models/nature/den_wolf/den_wolf.glb",
	"ice_wolf_den": "res://assets/models/nature/den_wolf/den_wolf.glb",
	"monkey_den": "res://assets/models/nature/den_monkey_nest/den_monkey_nest.glb",
	"flint": "res://assets/models/items/item_flint/item_flint.glb",
	"mushroom": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"glow_mushroom_node": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"ruin_mushroom_node": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"wild_root": "res://assets/models/items/item_wild_tuber/item_wild_tuber.glb",
	"water_root_node": "res://assets/models/items/item_wild_tuber/item_wild_tuber.glb",
	"grass": "res://assets/models/items/item_grass_fiber/item_grass_fiber.glb",
	"altar": "res://assets/models/structures/struct_revive_altar/struct_revive_altar.glb",
}

const STRUCTURE_MODELS := {
	"alchemy_furnace": "res://assets/models/structures/struct_alchemy_furnace/struct_alchemy_furnace.glb",
	"alchemy_furnace_t2": "res://assets/models/structures/struct_alchemy_furnace/struct_alchemy_furnace.glb",
	"campfire": "res://assets/models/structures/struct_campfire/struct_campfire.glb",
	"firepit": "res://assets/models/structures/struct_fire_pit/struct_fire_pit.glb",
	"chest": "res://assets/models/structures/struct_chest/struct_chest.glb",
	"talisman_chest": "res://assets/models/structures/struct_chest/struct_chest.glb",
	"realm_chest": "res://assets/models/structures/struct_chest/struct_chest.glb",
	"cooking_pot": "res://assets/models/structures/struct_cook_pot/struct_cook_pot.glb",
	"workbench": "res://assets/models/structures/struct_crafting_table/struct_crafting_table.glb",
	"crafting_table": "res://assets/models/structures/struct_crafting_table/struct_crafting_table.glb",
	"craft_table": "res://assets/models/structures/struct_crafting_table/struct_crafting_table.glb",
	"farm": "res://assets/models/structures/struct_herb_field/struct_herb_field.glb",
	"resurrection_altar": "res://assets/models/structures/struct_revive_altar/struct_revive_altar.glb",
	"awakening_altar": "res://assets/models/structures/struct_revive_altar/struct_revive_altar.glb",
	"guest_altar": "res://assets/models/structures/struct_revive_altar/struct_revive_altar.glb",
	"altar": "res://assets/models/structures/struct_revive_altar/struct_revive_altar.glb",
}

const ITEM_MODELS := {
	"grass_armor": "res://assets/models/items/armor_grass/armor_grass_item.glb",
	"roasted_fruit": "res://assets/models/items/food_berry_roasted/food_berry_roasted.glb",
	"fruit_soup": "res://assets/models/items/food_berry_soup/food_berry_soup.glb",
	"fruit_salad": "res://assets/models/items/food_berry_soup/food_berry_soup.glb",
	"charred_food": "res://assets/models/items/food_burnt/food_burnt.glb",
	"spoiled_food": "res://assets/models/items/food_burnt/food_burnt.glb",
	"mushroom_stew": "res://assets/models/items/food_meat_mushroom_stew/food_meat_mushroom_stew.glb",
	"detox_soup": "res://assets/models/items/food_meat_mushroom_stew/food_meat_mushroom_stew.glb",
	"roasted_meat": "res://assets/models/items/food_meat_roasted/food_meat_roasted.glb",
	"roasted_mushroom": "res://assets/models/items/food_mushroom_roasted/food_mushroom_roasted.glb",
	"spirit_feast": "res://assets/models/items/food_spirit_feast/food_spirit_feast.glb",
	"steamed_roots": "res://assets/models/items/food_steamed_tuber/food_steamed_tuber.glb",
	"roasted_root": "res://assets/models/items/food_steamed_tuber/food_steamed_tuber.glb",
	"bamboo": "res://assets/models/items/item_bamboo/item_bamboo.glb",
	"monster_core": "res://assets/models/items/item_beast_core_small/item_beast_core_small.glb",
	"monster_core_low": "res://assets/models/items/item_beast_core_small/item_beast_core_small.glb",
	"monster_core_mid": "res://assets/models/items/item_beast_core_small/item_beast_core_small.glb",
	"monster_core_high": "res://assets/models/items/item_beast_core_small/item_beast_core_small.glb",
	"flint": "res://assets/models/items/item_flint/item_flint.glb",
	"grass": "res://assets/models/items/item_grass_fiber/item_grass_fiber.glb",
	"seed": "res://assets/models/items/item_herb_seed/item_herb_seed.glb",
	"spirit_rice_seed": "res://assets/models/items/item_herb_seed/item_herb_seed.glb",
	"wood": "res://assets/models/items/item_log/item_log.glb",
	"hard_wood": "res://assets/models/items/item_log/item_log.glb",
	"damp_wood": "res://assets/models/items/item_log/item_log.glb",
	"frost_wood": "res://assets/models/items/item_log/item_log.glb",
	"meat": "res://assets/models/items/item_meat/item_meat.glb",
	"small_meat": "res://assets/models/items/item_meat_small/item_meat_small.glb",
	"monkey_fur": "res://assets/models/items/item_monkey_fur/item_monkey_fur.glb",
	"mutant_fruit": "res://assets/models/items/item_mutated_fruit/item_mutated_fruit.glb",
	"fur": "res://assets/models/items/item_pelt/item_pelt.glb",
	"thick_fur": "res://assets/models/items/item_pelt/item_pelt.glb",
	"ice_wolf_pelt": "res://assets/models/items/item_pelt/item_pelt.glb",
	"thunder_fur": "res://assets/models/items/item_pelt/item_pelt.glb",
	"pinecone": "res://assets/models/items/item_pine_cone/item_pine_cone.glb",
	"rope": "res://assets/models/items/item_rope/item_rope.glb",
	"spirit_fruit": "res://assets/models/items/item_spirit_berry/item_spirit_berry.glb",
	"fire_berry": "res://assets/models/items/item_spirit_berry/item_spirit_berry.glb",
	"ancient_fruit": "res://assets/models/items/item_spirit_berry/item_spirit_berry.glb",
	"herb": "res://assets/models/items/item_spirit_herb/item_spirit_herb.glb",
	"soul_herb": "res://assets/models/items/item_spirit_herb/item_spirit_herb.glb",
	"thunder_herb": "res://assets/models/items/item_spirit_herb/item_spirit_herb.glb",
	"snow_lotus": "res://assets/models/items/item_spirit_herb/item_spirit_herb.glb",
	"fire_lotus": "res://assets/models/items/item_spirit_herb/item_spirit_herb.glb",
	"spirit_stone": "res://assets/models/items/item_spirit_stone/item_spirit_stone.glb",
	"stone": "res://assets/models/items/item_stone/item_stone.glb",
	"basalt": "res://assets/models/items/item_stone/item_stone.glb",
	"quartz": "res://assets/models/items/item_stone/item_stone.glb",
	"gravel": "res://assets/models/items/item_stone/item_stone.glb",
	"carved_stone": "res://assets/models/items/item_stone/item_stone.glb",
	"twig": "res://assets/models/items/item_twigs/item_twigs.glb",
	"mushroom": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"glow_mushroom": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"ruin_mushroom": "res://assets/models/items/item_white_mushroom/item_white_mushroom.glb",
	"wild_root": "res://assets/models/items/item_wild_tuber/item_wild_tuber.glb",
	"water_root": "res://assets/models/items/item_wild_tuber/item_wild_tuber.glb",
	"fang": "res://assets/models/items/item_wolf_tooth/item_wolf_tooth.glb",
	"calm_pill": "res://assets/models/items/pill_calm_mind/pill_calm_mind.glb",
	"blood_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"antidote_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"swift_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"cool_jade_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"warm_yang_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"water_ward_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"conceal_pill": "res://assets/models/items/pill_heal/pill_heal.glb",
	"night_pill": "res://assets/models/items/pill_night_sight/pill_night_sight.glb",
	"pierce_mist_pill": "res://assets/models/items/pill_night_sight/pill_night_sight.glb",
	"revival_pill": "res://assets/models/items/pill_revive/pill_revive.glb",
	"minor_awakening_pill": "res://assets/models/items/pill_revive/pill_revive.glb",
	"mid_awakening_pill": "res://assets/models/items/pill_revive/pill_revive.glb",
	"full_awakening_pill": "res://assets/models/items/pill_revive/pill_revive.glb",
	"waste_pill": "res://assets/models/items/pill_waste/pill_waste.glb",
	"flint_axe": "res://assets/models/items/tool_axe_stone/tool_axe_stone.glb",
	"hammer": "res://assets/models/items/tool_hammer/tool_hammer.glb",
	"flint_pickaxe": "res://assets/models/items/tool_pickaxe_stone/tool_pickaxe_stone.glb",
	"spirit_pickaxe": "res://assets/models/items/tool_pickaxe_stone/tool_pickaxe_stone.glb",
	"shovel": "res://assets/models/items/tool_shovel/tool_shovel.glb",
	"torch": "res://assets/models/items/tool_torch/tool_torch.glb",
	"water_bottle": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"plain_water": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_thanh_moc": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_u_minh": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_xich_viem": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_loi_tri": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_huyen_bang": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spirit_water_co_van": "res://assets/models/items/tool_water_flask/tool_water_flask_empty.glb",
	"spear": "res://assets/models/items/weapon_spear/weapon_spear.glb",
	"dark_iron_spear": "res://assets/models/items/weapon_spear/weapon_spear.glb",
}

static var _cache: Dictionary = {}
static var _shadow_mat: StandardMaterial3D


static func all_paths() -> Array[String]:
	var seen := {}
	for dict in [PLAYER_MODELS, CREATURE_MODELS, NODE_MODELS, STRUCTURE_MODELS, ITEM_MODELS]:
		for path in dict.values():
			seen[str(path)] = true
	var out: Array[String] = []
	for path in seen.keys():
		out.append(str(path))
	out.sort()
	return out


static func resolve_path(kind: String, category: String, entity: Dictionary = {}) -> String:
	match category:
		"players":
			var cid := str(entity.get("character", "beast_bloodline"))
			if cid.is_empty():
				cid = "beast_bloodline"
			return str(PLAYER_MODELS.get(cid, PLAYER_DEFAULT))
		"creatures":
			return str(CREATURE_MODELS.get(kind, ""))
		"nodes":
			return str(NODE_MODELS.get(kind, ""))
		"structures":
			return str(STRUCTURE_MODELS.get(kind, ""))
		"drops":
			var item_id := str(entity.get("id", ""))
			return str(ITEM_MODELS.get(item_id, ""))
	return ""


static func load_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path] as PackedScene
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var scene := load(path) as PackedScene
	_cache[path] = scene
	return scene


static func instantiate(kind: String, category: String, entity: Dictionary = {}) -> Node3D:
	var path := resolve_path(kind, category, entity)
	var packed := load_scene(path)
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	if model == null:
		return null
	_fix_materials(model)
	model.name = "Model"
	if category == "drops":
		model.scale = Vector3.ONE * 1.4
	elif category == "nodes" and ("tree" in kind or "pine" in kind):
		model.scale = Vector3.ONE * 0.78
		model.position.y = -0.18
	var wrapper := Node3D.new()
	wrapper.add_child(model)
	_add_contact_shadow(wrapper, kind, category)
	wrapper.set_meta("has_glb", true)
	wrapper.set_meta("model_path", path)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null:
		wrapper.set_meta("anim_player", ap)
		for anim_name in ["idle", "walk", "run"]:
			if ap.has_animation(anim_name):
				var anim := ap.get_animation(anim_name)
				if anim != null:
					anim.loop_mode = Animation.LOOP_LINEAR
		if ap.has_animation("idle"):
			ap.play("idle")
	return wrapper


static func _fix_materials(root: Node) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat == null or mat.has_meta("hgk_fixed"):
				continue
			mat.metallic = 0.0
			mat.metallic_specular = 0.0
			mat.roughness = 0.90
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
			mat.albedo_color = Color(1.22, 1.22, 1.20, 1.0)
			mat.set_meta("hgk_fixed", true)


static func _get_shadow_mat() -> StandardMaterial3D:
	if _shadow_mat != null:
		return _shadow_mat
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(0.05, 0.04, 0.03, 0.48),
		Color(0.05, 0.04, 0.03, 0.22),
		Color(0.05, 0.04, 0.03, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64

	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.albedo_texture = tex
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_mat.no_depth_test = false
	return _shadow_mat


static func _add_contact_shadow(wrapper: Node3D, kind: String, category: String) -> void:
	var size := 1.2
	match category:
		"players":
			size = 1.15
		"creatures":
			size = 0.75 if kind in ["rabbit", "spirit_rabbit"] else 1.2
		"structures":
			size = 1.6 if kind in ["chest", "talisman_chest", "realm_chest", "cooking_pot"] else 2.2
		"nodes":
			if "tree" in kind or "pine" in kind:
				size = 2.6
			elif "den" in kind or kind in ["spring", "altar"]:
				size = 2.2
			elif kind in ["flint", "mushroom", "glow_mushroom_node", "ruin_mushroom_node", "wild_root", "water_root_node", "grass"]:
				size = 0.55
			else:
				size = 1.4
		"drops":
			size = 0.5
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.mesh = plane
	shadow.position = Vector3(0.0, 0.02, 0.0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.material_override = _get_shadow_mat()
	wrapper.add_child(shadow)
