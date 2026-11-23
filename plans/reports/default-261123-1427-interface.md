# Demo interface and renderer delivery

- DemoUI APIs: show_menu(message), show_game(), update_state(state, peer_id), set_status(message), set_target(entity), open_crafting(). Signals host_requested, join_requested, action_requested, leave_requested, save_requested.
- DST-inspired UX: five category rail left; Tab opens/closes crafting, B opens Thiên Thư; search/group filters; three bronze circular stats and 16 segment clock top right; 15 slot bottom hotbar. Ctrl drag splits; drag transfers; Shift click drops; right click equips/uses. Durability bars and percentage.
- Structure panel supports four ingredients, solvent, cooking/output, storage/altar funding, farm planting/watering/fertilizing/harvesting, spring actions, fire fuel/roast, ghost revival. Selected inventory slot determines source. World placement delegated to main controller.
- Render uses unchanged style_test.tscn as art base, source trees/rocks/materials, source gate/terrain/fog/environment and painted gradient on generated entities. Local prediction, interpolation, ghosts, beast scale, sense highlighting, torch/fire light, action/darkness procedural sound.
- All newly owned files below 200 lines. Godot full script compile: 132 scripts, zero broken. Root captured 1280x800 and compact viewport screenshots during integration.
- Latest headless host smoke reached ENet occupied port because root test host was already running; no script errors. No processes left running by this agent.
- Root owns final LAN/manual gameplay and screenshot verification; long 10-day multiplayer and exported build acceptance still require separate evidence.

Unresolved questions: none for interface contract.
