extends RefCounted
## Contextual controls shared by mouse, inventory and action panel.
var main
var plant_slot := -1

func handle(event: InputEvent) -> void:
	if main.state.is_empty():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel()
		elif event.keycode == KEY_Q:
			action("ability", {"name": "beast"})
		elif event.keycode == KEY_F:
			action("ability", {"name": "sense"})
		elif event.keycode == KEY_SPACE:
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
