extends RefCounted
## Contextual controls shared by mouse, inventory and action panel.
const Rules = preload("res://world/simulation/world_rules.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")
var main
var plant_slot := -1

func handle(event: InputEvent) -> void:
	if main.state.is_empty():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and not event.echo:
			cancel()
		elif event.keycode == SettingsManager.key_for("ability_1") and not event.echo:
			_trigger_ability(0)
		elif event.keycode == SettingsManager.key_for("ability_2") and not event.echo:
			_trigger_ability(1)
		elif event.keycode == SettingsManager.key_for("ability_3") and not event.echo:
			_trigger_ability(2)
		elif event.keycode == SettingsManager.key_for("quick_work"):
			_quick_work()
		elif event.keycode == SettingsManager.key_for("interact"):
			var player: Dictionary = main.state.players.get(str(main.multiplayer.get_unique_id()), {})
			if player.is_empty(): return
			var target: Dictionary = {}
			var distance := 3.0
			for entity in main.state.get("drops", []) + main.state.get("nodes", []):
				var d := Vector2(entity.position[0] - player.position[0], entity.position[2] - player.position[2]).length()
				if d < distance:
					distance = d
					target = entity
			if not target.is_empty():
				action("pickup" if target.get("kind") == "drop" else "work", {"uid": target.uid})
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		main.zoom = maxf(10, main.zoom - 2)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		main.zoom = minf(36, main.zoom + 2)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if not main.preview_recipe.is_empty() or plant_slot >= 0:
			cancel()
		else:
			context(main.view.get_target(main._mouse_world()))
	elif event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector3 = main._mouse_world()
		if not main.preview_recipe.is_empty():
			action("place", {"recipe": main.preview_recipe, "position": [point.x, 0.0, point.z]})
			cancel()
		elif plant_slot >= 0:
			main.session.intent("plant", {"slot": plant_slot, "position": [point.x, 0.0, point.z]})
			cancel()
		else:
			var target: Dictionary = main.view.get_target(point)
			main.ui.set_target(target)
			if not target.is_empty():
				var category := str(target.get("collection", ""))
				if category == "structures":
					if target.kind == "workbench": main.ui.open_crafting()
					var player: Dictionary = main.state.players.get(str(main.multiplayer.get_unique_id()), {})
					if player.get("inventory", {}).get("equipment", {}).get("hand", {}).get("id", "") == "hammer":
						action("attack", {"uid": target.uid})
				elif category in ["drops", "nodes", "creatures"]:
					action("pickup" if category == "drops" else ("attack" if category == "creatures" else "work"), {"uid": target.uid})

func context(target: Dictionary) -> void:
	if target.is_empty():
		return
	var uid := int(target.get("uid", -1))
	var kind := str(target.get("kind", ""))
	var slot: int = main.ui.selected_slot
	if kind in ["campfire", "firepit"]:
		action("roast", {"uid": uid, "slot": slot})
	elif kind == "spring":
		action("water", {"uid": uid, "mode": "fill"})
	elif kind == "farm":
		action("water", {"uid": uid, "mode": "harvest"})
	elif kind in ["cooking_pot", "alchemy_furnace"]:
		action("take" if not str(target.get("output", "")).is_empty() else "insert", {"uid": uid, "slot": slot})
	elif kind == "player" and target.get("ghost", false):
		action("revive", {"peer_id": uid})
	elif kind == "resurrection_altar":
		action("revive", {"uid": uid})

func action(verb: String, args: Dictionary) -> void:
	if verb == "place_preview":
		main.preview_recipe = str(args.get("recipe", ""))
	elif verb == "plant" and not args.has("uid"):
		plant_slot = int(args.get("slot", -1))
	else:
		main.session.intent(verb, args)

func cancel() -> void:
	main.preview_recipe = ""
	plant_slot = -1
	main.preview.visible = false

func _trigger_ability(idx: int) -> void:
	var player: Dictionary = main.state.get("players", {}).get(str(main.multiplayer.get_unique_id()), {})
	if player.is_empty():
		return
	var cdef = WorldAbilities.character_def(player)
	if cdef == null or idx < 0 or idx >= cdef.abilities.size():
		return
	var ab_id := String(cdef.abilities[idx].id)
	var args: Dictionary = {"name": ab_id}
	if ab_id == "devour":
		args["slot"] = main.ui.selected_slot
	elif ab_id in ["command_puppet", "yin_yang_palm"]:
		var tgt: Dictionary = main.view.get_target(main._mouse_world())
		if not tgt.is_empty() and tgt.has("uid"):
			args["uid"] = int(tgt.uid)
	elif ab_id == "shadow_step":
		var mp: Vector3 = main._mouse_world()
		args["position"] = [mp.x, 0.0, mp.z]
	action("ability", args)


func _quick_work() -> void:
	var player: Dictionary = main.state.get("players", {}).get(str(main.multiplayer.get_unique_id()), {})
	if player.is_empty():
		return
	var result := find_work_candidate(player, main.state)
	var node: Dictionary = result.get("node", {})
	if not node.is_empty():
		action("work", {"uid": node.uid, "auto_equip": true})
	elif not str(result.get("missing_tool", "")).is_empty() and main.ui:
		main.ui.set_status("UI_NEED_" + str(result.missing_tool).to_upper())

func get_work_hint(player: Dictionary, state: Dictionary) -> String:
	if player.is_empty() or state.is_empty() or player.get("ghost", false):
		return ""
	var result := find_work_candidate(player, state)
	var node: Dictionary = result.get("node", {})
	if node.is_empty():
		return ""
	var tool := str(result.get("tool", ""))
	var verb_key := "UI_VERB_GATHER"
	if tool == "axe":
		verb_key = "UI_VERB_CHOP"
	elif tool == "pickaxe":
		verb_key = "UI_VERB_MINE"
	elif tool == "shovel":
		verb_key = "UI_VERB_DIG"
	var node_name := TranslationServer.translate(str(result.get("name_key", "")))
	return "[F] %s %s" % [TranslationServer.translate(verb_key), node_name]

func find_work_candidate(player: Dictionary, state: Dictionary) -> Dictionary:
	var p: Array = player.get("position", [0.0, 0.0, 0.0])
	var p2 := Vector2(float(p[0]), float(p[2]))
	var best_node: Dictionary = {}
	var best_tool := ""
	var best_name_key := ""
	var best_tier := -1
	var best_dist := 999999.0
	var missing_tool := ""
	var missing_dist := 999999.0
	for node in state.get("nodes", []):
		var np: Array = node.get("position", [0.0, 0.0, 0.0])
		var dist := p2.distance_to(Vector2(float(np[0]), float(np[2])))
		if dist > 3.0:
			continue
		var req := _node_requirement(node, player)
		if req.get("skip", false):
			continue
		var tool := str(req.get("tool", ""))
		var req_tier := int(req.get("tier", 1))
		var tier := 1
		if not tool.is_empty():
			var status := _player_tool_status(player, tool, req_tier)
			if status == 0:
				if dist < missing_dist:
					missing_dist = dist
					missing_tool = tool
				continue
			tier = status + 1
		if tier > best_tier or (tier == best_tier and dist < best_dist):
			best_tier = tier
			best_dist = dist
			best_node = node
			best_tool = tool
			best_name_key = str(req.get("name_key", ""))
	return {"node": best_node, "tool": best_tool, "name_key": best_name_key, "missing_tool": missing_tool}

func _node_requirement(node: Dictionary, player: Dictionary) -> Dictionary:
	if node.is_empty() or node.get("sapling", false):
		return {"skip": true}
	var kind := str(node.get("kind", ""))
	if kind == "spring" and node.get("frozen", false):
		return {"skip": false, "tool": "pickaxe", "tier": 1, "name_key": "WORLD_" + kind.to_upper()}
	var definition = Rules.node(kind)
	if definition == null or definition.stages.is_empty():
		return {"skip": true}
	var tool: String = ["", "axe", "pickaxe", "shovel"][definition.required_tool]
	var req_tier: int = int(definition.get("required_tool_tier") if definition.get("required_tool_tier") != null else 1)
	if kind in ["berry_bush", "grass", "twig_bush"] and _player_tool_status(player, "shovel", 1) == 2:
		tool = "shovel"
		req_tier = 1
	if node.get("depleted", false) and (definition.required_tool == 2 or kind in ["rock", "spirit_rock"]):
		return {"skip": true}
	if int(node.get("stage", 0)) > 0 and kind in ["tree", "berry_bush", "grass", "twig_bush"]:
		tool = "shovel"
		req_tier = 1
	if float(node.get("regrow", 0.0)) > 0.0 and tool != "shovel":
		return {"skip": true}
	var name_key := str(definition.name_key) if not str(definition.name_key).is_empty() else "WORLD_" + kind.to_upper()
	return {"skip": false, "tool": tool, "tier": req_tier, "name_key": name_key}

func _player_tool_status(player: Dictionary, tool: String, min_tier: int) -> int:
	if float(player.get("beast_time", 0.0)) > 0.0:
		return 0
	var types := {"axe": 1, "pickaxe": 2, "shovel": 3}
	var target_type := int(types.get(tool, -1))
	if target_type < 0:
		return 0
	var inv: Dictionary = player.get("inventory", {})
	var hand: Dictionary = inv.get("equipment", {}).get("hand", {})
	if _slot_matches_tool(hand, target_type, min_tier):
		return 2
	for slot in inv.get("slots", []):
		if _slot_matches_tool(slot, target_type, min_tier):
			return 1
	return 0

func _slot_matches_tool(slot: Variant, target_type: int, min_tier: int) -> bool:
	if not slot is Dictionary or slot.is_empty():
		return false
	var item = ItemDB.get_item(str(slot.get("id", "")))
	if item == null:
		return false
	var tier_val := int(item.get("tool_tier") if item.get("tool_tier") != null else 1)
	return int(item.tool_type) == target_type and tier_val >= min_tier
