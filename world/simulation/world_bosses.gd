extends RefCounted

const Rules = preload("res://world/simulation/world_rules.gd")

const BIOME_BOSS := {
	"nether_swamp": "boss_ghost_general",
	"crimson_volcano": "boss_flame_wolf",
	"bamboo_forest": "boss_iron_turtle",
	"thunder_gorge": "boss_thunder_roc",
	"frost_peaks": "boss_frost_wyrm",
	"ancient_ruins": "boss_ancient_warden",
}

const CORE_IDS := ["monster_core_low", "monster_core", "monster_core_mid", "monster_core_high"]


static func boss_for_biome(biome: String) -> String:
	return BIOME_BOSS.get(biome, "boss_iron_turtle")


static func summon_boss(world, player: Dictionary, args: Dictionary) -> bool:
	var altar: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if altar.is_empty() or str(altar.get("kind", "")) != "altar" or not world.near(player, altar, 3.5):
		return false
	var biome := str(altar.get("biome", world.biome_at(altar.position)))
	var boss_kind := boss_for_biome(biome)
	for c in world.state.get("creatures", []):
		if str(c.get("kind", "")) == boss_kind and float(c.get("health", 0.0)) > 0.0:
			return false
	var inv = world.inventory(player)
	var total := 0
	for cid in CORE_IDS:
		total += inv.count_item(cid)
	if total < 3:
		return false
	var need := 3
	for cid in CORE_IDS:
		if need <= 0:
			break
		var have: int = inv.count_item(cid)
		if have > 0:
			var take := mini(need, have)
			inv.remove_item(cid, take)
			need -= take
	player.inventory = inv.to_dict()
	var cdef = Rules.creature(boss_kind)
	var hp := float(cdef.max_health) if cdef != null else 450.0
	var pos := [float(altar.position[0]) + 3.0, 0.0, float(altar.position[2]) + 3.0]
	var boss: Dictionary = world.entity(boss_kind, pos)
	boss.merge({
		"is_boss": true,
		"boss_biome": biome,
		"health": hp,
		"max_health": hp,
		"state": "chase",
		"home": pos.duplicate(),
		"cooldown": 0.0,
		"special_cd": 6.0,
		"respawn": 0.0,
		"hit_flash": 0.0,
		"stolen": [],
		"effects": {},
		"no_respawn": true,
		"shrouded": boss_kind == "boss_ghost_general",
		"armored": boss_kind == "boss_iron_turtle",
		"shield_active": boss_kind == "boss_ancient_warden",
		"frost_armor": boss_kind == "boss_frost_wyrm",
		"grounded_timer": 0.0,
		"cracked_timer": 0.0,
		"melted_timer": 0.0,
		"shield_broken_timer": 0.0,
		"rod_absorbed": 0,
	})
	world.add_entity("creatures", boss)
	world.log_event("boss_summoned", {"kind": boss_kind, "biome": biome})
	return true


static func modify_incoming_damage(world, boss: Dictionary, attacker: Dictionary, damage: float, hand: Dictionary) -> float:
	if not boss.get("is_boss", false):
		return damage
	var kind := str(boss.get("kind", ""))
	var ttype := str(world.Tempering.get_temper_type(hand))
	match kind:
		"boss_ghost_general":
			var lit_lantern := false
			for s in world.index.entities_near(boss.position, 8.0, "structures"):
				if str(s.get("kind", "")) == "soul_lantern" or (str(s.get("kind", "")) == "light_pillar" and float(s.get("fuel", 0.0)) > 0.0):
					lit_lantern = true
					break
			var revealed: bool = lit_lantern or ttype == "u_minh" or world.Effects.has(attacker, "pierce_mist") or world.Effects.has(attacker, "spirit_sight")
			if boss.get("shrouded", true) and not revealed:
				return 0.0
			boss["shrouded"] = false
			return damage
		"boss_flame_wolf":
			if ttype == "huyen_bang":
				boss["channel_timer"] = 0.0
				world.Creatures.apply_effect(world, boss, "stun", 2.0)
				return damage * 1.25
			return damage
		"boss_iron_turtle":
			if float(boss.get("cracked_timer", 0.0)) > 0.0:
				return damage * 1.5
			return damage * 0.3
		"boss_thunder_roc":
			if float(boss.get("grounded_timer", 0.0)) > 0.0:
				return damage * 1.3
			return damage * 0.7
		"boss_frost_wyrm":
			var near_fire := false
			for s in world.index.entities_near(boss.position, 6.0, "structures"):
				if str(s.get("kind", "")) in ["campfire", "firepit"] and float(s.get("fuel", 0.0)) > 0.0:
					near_fire = true
					break
			if ttype == "xich_viem" or near_fire:
				boss["melted_timer"] = 10.0
			if float(boss.get("melted_timer", 0.0)) > 0.0:
				return damage * 1.25
			return damage * 0.65
		"boss_ancient_warden":
			if ttype == "loi_tri":
				boss["shield_broken_timer"] = 10.0
			if float(boss.get("shield_broken_timer", 0.0)) > 0.0:
				return damage * 1.25
			return damage * 0.2
	return damage


static func on_talisman_hit(world, boss: Dictionary, talisman_effect: String) -> void:
	if not boss.get("is_boss", false):
		return
	var kind := str(boss.get("kind", ""))
	if kind == "boss_flame_wolf" and talisman_effect == "frost":
		boss["channel_timer"] = 0.0
		world.Creatures.apply_effect(world, boss, "stun", 3.0)
	elif kind == "boss_ancient_warden" and talisman_effect == "bind":
		boss["shield_broken_timer"] = 10.0
	elif kind == "boss_ghost_general" and talisman_effect == "true_sight":
		boss["shrouded"] = false
