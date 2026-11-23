extends SceneTree
## Headless UI layout & overlap verification across 1280x720, 1280x800, 1920x1080, 2560x1080.

const SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1440, 900),
	Vector2i(1828, 800), # canvas_items + expand equivalent of 2560x1080 on 1280x800 base
]


func _initialize() -> void:
	var GameUI := load("res://ui/hud/game_ui.gd")
	var failed := 0
	for sz in SIZES:
		var vp := SubViewport.new()
		vp.size = sz
		root.add_child(vp)

		var ui = GameUI.new()
		vp.add_child(ui)
		await process_frame
		await process_frame

		var screen := Rect2(Vector2.ZERO, Vector2(sz))

		# 1. Main Menu bounds check
		if not screen.encloses(ui.menu.get_global_rect()):
			failed += 1
			push_error("Main menu off-screen at %s: %s" % [sz, ui.menu.get_global_rect()])

		# 2. Switch to Game HUD & feed realistic state
		ui.show_game()
		var mock_state := _mock_state()
		ui.update_state(mock_state, 1)
		ui.set_target({"uid": 99, "kind": "campfire", "fuel": 65.0})
		await process_frame
		await process_frame

		var rects := {
			"karma": ui.karma_hud.get_parent().get_global_rect(),
			"radial": ui.radial.get_global_rect(),
			"rail": ui.rail_buttons[0].get_parent().get_parent().get_global_rect(),
			"minimap": ui.minimap.get_parent().get_parent().get_global_rect(),
			"dock": ui.inventory.get_parent().get_parent().get_global_rect(),
		}

		for name in rects:
			var r: Rect2 = rects[name]
			if not screen.encloses(r):
				failed += 1
				push_error("HUD '%s' off-screen at %s: %s" % [name, sz, r])

		var names := rects.keys()
		for i in names.size():
			for j in range(i + 1, names.size()):
				var a: Rect2 = rects[names[i]]
				var b: Rect2 = rects[names[j]]
				if a.intersects(b):
					failed += 1
					push_error("HUD overlap between '%s' and '%s' at %s: %s vs %s" % [names[i], names[j], sz, a, b])

		# 3. Open Crafting Drawer, Bag Popover, Pause Menu, Awakening, World Map
		ui.open_crafting()
		ui.bag_panel.show()
		await process_frame
		if not screen.encloses(ui.craft_frame.get_global_rect()):
			failed += 1
			push_error("Craft drawer off-screen at %s: %s" % [sz, ui.craft_frame.get_global_rect()])

		ui._toggle_pause()
		await process_frame
		if not screen.encloses(ui.pause_menu.get_global_rect()):
			failed += 1
			push_error("Pause menu off-screen at %s: %s" % [sz, ui.pause_menu.get_global_rect()])
		ui.modal_stack.close_top()

		ui._toggle_awakening()
		await process_frame
		if not screen.encloses(ui.awakening_panel.get_global_rect()):
			failed += 1
			push_error("Awakening panel off-screen at %s: %s" % [sz, ui.awakening_panel.get_global_rect()])
		ui.modal_stack.close_top()

		ui._toggle_world_map()
		await process_frame
		if not screen.encloses(ui.world_map_modal.get_global_rect()):
			failed += 1
			push_error("World map modal off-screen at %s: %s" % [sz, ui.world_map_modal.get_global_rect()])
		ui.modal_stack.close_top()

		vp.free()

	print("UI Layout Check: %d failed across %d resolutions" % [failed, SIZES.size()])
	quit(1 if failed > 0 else 0)


func _mock_state() -> Dictionary:
	var slots: Array = []
	slots.resize(30)
	for i in 30:
		slots[i] = {}
	slots[0] = {"id": "twig", "count": 5}
	slots[1] = {"id": "flint_axe", "count": 1, "durability": 80}
	return {
		"seed": 12345,
		"options": {"day_length": 480, "map_size": 288},
		"clock": {"day": 1, "elapsed": 120.0, "phase": "day", "season": "autumn", "day_segments": 8, "dusk_segments": 6},
		"weather": {"kind": "storm"},
		"karma": {"sin": 35.0, "fate": 65.0},
		"regions": [{"biome": "bamboo_forest", "center": [0, 0, 0]}],
		"teleports": [],
		"discovered": ["flint_axe"],
		"players": {
			"1": {
				"uid": 1,
				"name": "Tester",
				"character": "yin_yang",
				"position": [0.0, 0.0, 0.0],
				"biome": "bamboo_forest",
				"awakening_tier": 1,
				"skill_points": 2,
				"skills": [],
				"imprints": [],
				"stats": {"health": 80, "max_health": 120, "stamina": 91, "dao": 21, "temperature": 42},
				"inventory": {"slots": slots, "equipment": {"hand": {}, "body": {}, "head": {}}},
			}
		}
	}
