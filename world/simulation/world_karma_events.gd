extends RefCounted


static func execute(world, ev: KarmaEventDef) -> void:
	if ev == null:
		return
	var p: Dictionary = ev.params
	match ev.kind:
		"spawn_npc":
			_spawn_npc(world, p)
		"spawn_hostiles":
			_spawn_hostiles(world, p)
		"steal_chest":
			_steal_chest(world, p)
		"open_secret_realm":
			_open_secret_realm(world, p)
		"grant_recipe":
			_grant_recipe(world, p)
		"tame_beast":
			_tame_beast(world, p)


static func _anchor_pos(world) -> Array:
	var structures: Array = world.state.get("structures", [])
	if not structures.is_empty():
		var avg := [0.0, 0.0, 0.0]
		for s in structures:
			avg[0] += float(s.position[0])
			avg[2] += float(s.position[2])
		avg[0] /= float(structures.size())
		avg[2] /= float(structures.size())
		return avg
	for pl in world.state.get("players", {}).values():
		return pl.position.duplicate()
	return [0.0, 0.0, 0.0]


static func _offset_pos(world, base: Array, radius: float = 6.0) -> Array:
	var a: float = world.rng.randf() * TAU
	var limit: float = world.map_half() - 1.0
	return [
		clampf(float(base[0]) + cos(a) * radius, -limit, limit),
		0.0,
		clampf(float(base[2]) + sin(a) * radius, -limit, limit),
	]


static func _spawn_npc(world, params: Dictionary) -> void:
	var faction := str(params.get("faction", "merchant"))
	var pos := _offset_pos(world, _anchor_pos(world), 5.0)
	var npc: Dictionary = world.entity(faction, pos)
	npc.merge({
		"faction": faction,
		"hostile": false,
		"health": 120.0,
		"max_health": 120.0,
		"lifetime": world.day_length(),
		"offers": params.get("offers", []).duplicate(true),
		"requests": params.get("requests", []).duplicate(true),
		"stolen": [],
		"cooldown": 0.0,
		"effects": {},
	})
	if faction == "wanderer" and npc.requests.is_empty():
		var pool := ["herb", "spirit_fruit", "wood", "stone", "mushroom", "wild_root"]
		var chosen := {}
		for _i in 3:
			var id: String = pool[world.rng.randi_range(0, pool.size() - 1)]
			chosen[id] = int(chosen.get(id, 0)) + 1
		var reqs: Array = []
		for id in chosen:
			reqs.append({"id": id, "count": chosen[id]})
		npc.requests = reqs
	world.add_entity("npcs", npc)


static func _spawn_hostiles(world, params: Dictionary) -> void:
	var kind := str(params.get("kind", "enforcer"))
	var count := int(params.get("count", 2))
	var base := _anchor_pos(world)
	var is_creature := kind in ["wraith", "wolf"]
	for _i in count:
		var pos := _offset_pos(world, base, 7.0)
		if is_creature:
			var c: Dictionary = world.entity(kind, pos)
			c.merge({"health": 70.0, "max_health": 70.0, "state": "chase", "home": pos.duplicate(), "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "no_respawn": true})
			world.add_entity("creatures", c)
		else:
			var npc: Dictionary = world.entity(kind, pos)
			npc.merge({
				"faction": kind,
				"hostile": true,
				"health": float(params.get("health", 110.0)),
				"max_health": float(params.get("health", 110.0)),
				"damage": float(params.get("damage", 16.0)),
				"lifetime": world.day_length(),
				"drops": params.get("drops", []).duplicate(true),
				"cooldown": 0.0,
				"effects": {},
			})
			world.add_entity("npcs", npc)
	if bool(params.get("wanted_curse", false)):
		for pl in world.state.get("players", {}).values():
			world.Effects.apply(world, pl, "wanted_curse", 1.0, world.day_length())


static func _steal_chest(world, _params: Dictionary) -> void:
	var target_chest: Dictionary = {}
	for s in world.state.get("structures", []):
		if s.kind == "chest":
			for slot in s.get("slots", []):
				if slot is Dictionary and not slot.is_empty():
					target_chest = s
					break
		if not target_chest.is_empty():
			break
	if target_chest.is_empty():
		return
	var stolen: Array = []
	var to_take: int = world.rng.randi_range(1, 3)
	for i in target_chest.slots.size():
		if to_take <= 0:
			break
		var slot = target_chest.slots[i]
		if slot is Dictionary and not slot.is_empty():
			var take_count: int = mini(to_take, int(slot.count))
			var copy: Dictionary = slot.duplicate(true)
			copy.count = take_count
			stolen.append(copy)
			slot.count -= take_count
			to_take -= take_count
			if int(slot.count) <= 0:
				target_chest.slots[i] = {}
	world.touch(int(target_chest.uid))
	var pos := _offset_pos(world, target_chest.position, 2.5)
	var beggar: Dictionary = world.entity("beggar", pos)
	beggar.merge({"faction": "beggar", "hostile": false, "health": 60.0, "max_health": 60.0, "lifetime": world.day_length() * 0.5, "stolen": stolen, "cooldown": 0.0, "effects": {}})
	world.add_entity("npcs", beggar)


static func _open_secret_realm(world, _params: Dictionary) -> void:
	var pos := _offset_pos(world, _anchor_pos(world), 6.0)
	var portal: Dictionary = world.entity("secret_realm_portal", pos)
	portal.merge({"biome": world.biome_at(pos), "lifetime": world.day_length()})
	world.add_entity("nodes", portal)


static func _grant_recipe(world, params: Dictionary) -> void:
	var rid := str(params.get("recipe_id", "conceal_pill"))
	if not world.state.has("forbidden_recipes"):
		world.state["forbidden_recipes"] = []
	if not rid in world.state.forbidden_recipes:
		world.state.forbidden_recipes.append(rid)
	world.discover(rid)


static func _tame_beast(world, _params: Dictionary) -> void:
	var owner_peer := 1
	var pos := _anchor_pos(world)
	for pid in world.state.get("players", {}):
		owner_peer = int(pid)
		pos = world.state.players[pid].position.duplicate()
		break
	var spawn_pos := _offset_pos(world, pos, 3.0)
	var beast: Dictionary = world.entity("wolf", spawn_pos)
	beast.merge({
		"ally": true,
		"owner_peer": owner_peer,
		"health": 120.0,
		"max_health": 120.0,
		"state": "idle",
		"home": spawn_pos.duplicate(),
		"cooldown": 0.0,
		"respawn": 0.0,
		"hit_flash": 0.0,
		"stolen": [],
		"effects": {},
		"lifetime": world.day_length(),
	})
	world.add_entity("creatures", beast)
