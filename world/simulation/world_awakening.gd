extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

const WAVE_DURATION := 12.0
const TOTAL_WAVES := 3
const MAX_ALTAR_DIST := 12.0


static func _tier_requirements(tier: int) -> Dictionary:
	match tier:
		1:
			return {"pill": "minor_awakening_pill", "cores": ["monster_core_low", "monster_core"], "core_count": 3}
		2:
			return {"pill": "mid_awakening_pill", "cores": ["monster_core_mid", "monster_core"], "core_count": 3}
		3:
			return {"pill": "full_awakening_pill", "cores": ["monster_core_high"], "core_count": 3}
		_:
			return {}


static func _has_ritual_for_peer(world, peer_uid: int) -> bool:
	for r in world.state.get("rituals", []):
		if int(r.get("owner_uid", 0)) == peer_uid:
			return true
	return false


static func start_ritual(world, player: Dictionary, args: Dictionary) -> bool:
	var tier := int(player.get("awakening_tier", 0)) + 1
	if tier > 3 or _has_ritual_for_peer(world, int(player.uid)):
		return false
	var altar: Dictionary = world.index.find_in("structures", args.get("uid", -1))
	if altar.is_empty() or str(altar.get("kind", "")) != "awakening_altar" or not world.near(player, altar, 3.5):
		return false
	var req := _tier_requirements(tier)
	if req.is_empty():
		return false
	var inv = world.inventory(player)
	if inv.count_item(req.pill) < 1:
		return false
	var total_cores := 0
	for cid in req.cores:
		total_cores += inv.count_item(cid)
	if total_cores < int(req.core_count):
		return false
	inv.remove_item(req.pill, 1)
	var need := int(req.core_count)
	for cid in req.cores:
		if need <= 0:
			break
		var have: int = inv.count_item(cid)
		if have > 0:
			var take := mini(need, have)
			inv.remove_item(cid, take)
			need -= take
	player.inventory = inv.to_dict()
	var cdef = world.Abilities.character_def(player)
	var trib_id := String(cdef.tribulation_id) if cdef != null else "trib_beast_rage"
	var ritual := {
		"id": world.next_uid,
		"owner_uid": int(player.uid),
		"owner_peer": -int(player.uid),
		"altar_uid": int(altar.uid),
		"position": altar.position.duplicate(),
		"tier": tier,
		"tribulation": trib_id,
		"wave": 1,
		"wave_timer": WAVE_DURATION,
		"lightning_timer": 2.0,
		"mad_timer": 0.0,
		"dao_dir": 1.0,
		"strikes": 0,
	}
	world.next_uid += 1
	if not world.state.has("rituals") or not world.state.rituals is Array:
		world.state["rituals"] = []
	world.state.rituals.append(ritual)
	_spawn_wave(world, player, ritual)
	world.log_event("awakening_started", {"name": player.name, "tier": tier})
	return true


static func _spawn_wave(world, player: Dictionary, ritual: Dictionary) -> void:
	var pos: Array = ritual.position
	var tier := int(ritual.tier)
	var count := 1 + tier
	var kinds := ["wolf", "ruin_wraith"] if tier >= 2 else ["wolf"]
	for i in count:
		var ang: float = world.rng.randf() * TAU
		var limit: float = world.map_half() - 1.0
		var spos := [clampf(float(pos[0]) + cos(ang) * 9.0, -limit, limit), 0.0, clampf(float(pos[2]) + sin(ang) * 9.0, -limit, limit)]
		var kind: String = kinds[i % kinds.size()]
		var c: Dictionary = world.entity(kind, spos)
		c.merge({"health": 50.0 + tier * 20.0, "max_health": 50.0 + tier * 20.0, "state": "chase", "home": pos.duplicate(), "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "no_respawn": true})
		world.add_entity("creatures", c)
	if str(ritual.tribulation) == "trib_puppeteer":
		var peer := int(ritual.owner_peer)
		var guards := _count_guard_puppets(world, peer)
		for _g in maxi(0, 2 - guards):
			var p_pos := [float(pos[0]) + 1.5, 0.0, float(pos[2]) + 1.5]
			var pup: Dictionary = world.entity("puppet_guard", p_pos)
			pup.merge({"task": "guard", "owner_peer": peer, "health": 100.0, "max_health": 100.0, "fuel": 60.0, "state": "idle", "cooldown": 0.0, "target_uid": -1, "lifetime": 120.0})
			world.add_entity("puppets", pup)


static func _count_guard_puppets(world, peer_id: int) -> int:
	var count := 0
	for p in world.state.get("puppets", []):
		if str(p.get("task", "")) == "guard" and int(p.get("owner_peer", 0)) == peer_id and float(p.get("health", 0.0)) > 0.0:
			count += 1
	return count


static func step(world, delta: float) -> void:
	var rituals: Array = world.state.get("rituals", [])
	if rituals.is_empty():
		return
	var next_rituals: Array = []
	for r in rituals:
		var player := _find_owner(world, int(r.get("owner_peer", 1)))
		if player.is_empty() or player.get("ghost", false) or world.distance(player.position, r.position) > MAX_ALTAR_DIST:
			world.log_event("awakening_failed", {"tier": r.get("tier", 1)})
			continue
		r.lightning_timer = float(r.get("lightning_timer", 2.0)) - delta
		if float(r.lightning_timer) <= 0.0:
			r.lightning_timer = 3.5
			var off := [world.rng.randf_range(-4.5, 4.5), 0.0, world.rng.randf_range(-4.5, 4.5)]
			world.Weather.schedule_lightning(world, [float(r.position[0]) + off[0], 0.0, float(r.position[2]) + off[2]])
		var failed := _step_tribulation(world, player, r, delta)
		if failed:
			world.log_event("awakening_failed", {"name": player.name, "tier": r.get("tier", 1)})
			continue
		r.wave_timer = float(r.wave_timer) - delta
		if float(r.wave_timer) <= 0.0:
			if _wave_end_failed(world, player, r):
				world.log_event("awakening_failed", {"name": player.name, "tier": r.get("tier", 1)})
				continue
			if int(r.wave) >= TOTAL_WAVES:
				_complete(world, player, int(r.tier))
				continue
			r.wave = int(r.wave) + 1
			r.wave_timer = WAVE_DURATION
			_spawn_wave(world, player, r)
		next_rituals.append(r)
	world.state["rituals"] = next_rituals


static func _step_tribulation(world, player: Dictionary, r: Dictionary, delta: float) -> bool:
	var stats: Dictionary = player.get("stats", {})
	match str(r.get("tribulation", "")):
		"trib_beast_rage":
			player["rage"] = minf(100.0, float(player.get("rage", 0.0)) + 12.0 * delta)
			if player.get("mad", false):
				r.mad_timer = float(r.get("mad_timer", 0.0)) + delta
				if float(r.mad_timer) > 6.0:
					world.hurt(player, 10.0 * delta)
		"trib_devourer":
			player["poison"] = float(player.get("poison", 0.0)) + 6.0 * delta
			stats["poison"] = player["poison"]
			if float(player["poison"]) > float(player.get("poison_threshold", 150.0)):
				world.hurt(player, 18.0 * delta)
		"trib_yin_yang":
			var dao := float(stats.get("dao", 50.0)) + float(r.get("dao_dir", 1.0)) * 8.0 * delta
			if dao >= 75.0:
				r["dao_dir"] = -1.0
			elif dao <= 25.0:
				r["dao_dir"] = 1.0
			stats["dao"] = clampf(dao, 0.0, 100.0)
	return float(stats.get("health", 0.0)) <= 0.0 or player.get("ghost", false)


static func _wave_end_failed(world, player: Dictionary, r: Dictionary) -> bool:
	var trib := str(r.get("tribulation", ""))
	if trib == "trib_puppeteer":
		return _count_guard_puppets(world, int(r.owner_peer)) <= 0
	if trib == "trib_yin_yang":
		var dao := float(player.get("stats", {}).get("dao", 50.0))
		if dao < 35.0 or dao > 65.0:
			r["strikes"] = int(r.get("strikes", 0)) + 1
			world.hurt(player, 25.0)
			return int(r.strikes) >= 2 or player.get("ghost", false)
	return false


static func _complete(world, player: Dictionary, tier: int) -> void:
	player["awakening_tier"] = tier
	player["skill_points"] = int(player.get("skill_points", 0)) + 1
	var base_hp := float(player.stats.get("base_max_health", Rules.BASE_MAX_HEALTH)) + 15.0
	player.stats["base_max_health"] = base_hp
	var revivals := clampi(int(player.get("deaths", 0)), 0, 2)
	player.stats["max_health"] = base_hp * (1.0 - 0.25 * revivals)
	player.stats["health"] = minf(float(player.stats["max_health"]), float(player.stats.get("health", 0.0)) + 25.0)
	world.log_event("awakening_complete", {"name": player.name, "tier": tier})


static func _find_owner(world, peer_id: int) -> Dictionary:
	return world.state.players.get(str(peer_id), {})
