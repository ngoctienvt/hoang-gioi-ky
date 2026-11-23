extends RefCounted
const Structures = preload("res://world/simulation/world_structures.gd")
const Rules = preload("res://world/simulation/world_rules.gd")
const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")


static func attack(world, player: Dictionary, args: Dictionary) -> bool:
	if player.attack_cd > 0:
		return false
	var target: Dictionary = world.find_any(args.get("uid", -1))
	var peer = args.get("peer_id", -int(args.get("uid", 1)) if args.get("uid", 1) is int else -1)
	var other: Dictionary = world.state.players.get(str(peer), {})
	if not other.is_empty():
		if not player.get("mad", false) or other == player or other.ghost:
			return false
		target = other
	if target.is_empty() or not world.near(player, target, 2.8):
		return false
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	var damage := 15.0 if hand.is_empty() else maxf(15, float(world.item(hand.id).get("damage", 15)))
	if player.beast_time > 0:
		damage = 35.0
		if world.Skills.has_skill(player, "beast_t1_ferocity"):
			damage *= 1.3
		if world.Skills.has_skill(player, "beast_t3_apex"):
			damage *= 1.2
	elif hand.is_empty():
		var cdef = world.Abilities.character_def(player)
		if cdef != null:
			damage *= float(cdef.unarmed_damage_mult)
	if world.Skills.has_skill(player, "devour_t3_venom_strike") and float(player.get("poison", 0.0)) > 0.0:
		damage *= 1.25
	if world.Effects.has(player, "damage_boost"):
		damage *= (1.0 + world.Effects.magnitude(player, "damage_boost", 0.35))
	var col: String = world.index.collection_of.get(int(target.get("uid", 0)), "")
	if not other.is_empty():
		world.hurt(other, damage)
	elif col in ["creatures", "npcs"]:
		var dealt := damage_target(world, player, target, damage, hand, 0.4)
		if dealt < 0.0:
			return false
		if col == "creatures":
			if player.beast_time > 0 and world.Skills.has_skill(player, "beast_t2_bloodlust"):
				player.stats["health"] = minf(float(player.stats.get("max_health", Rules.BASE_MAX_HEALTH)), float(player.stats.get("health", 0.0)) + dealt * 0.15)
			world.Creatures.notify_noise(world, player.position, 8.0)
		if world.index.by_uid.has(int(target.uid)):
			world.Tempering.apply_hit(world, player, target, hand)
	elif col == "structures":
		if not world.has_tool(player, "hammer"):
			return false
		world.Creatures.notify_noise(world, player.position, 8.0)
		target.health -= damage
		if target.health <= 0:
			Structures.destroy(world, target, true)
		else:
			world.touch(int(target.uid))
	else:
		return false
	var cold_cd := float(player.get("stats", {}).get("temperature", 50.0)) < 30.0
	if world.Skills.has_imprint_effect(player, "frost_immunity"):
		cold_cd = false
	player.attack_cd = 0.65 * (1.25 if cold_cd else 1.0)
	if player.beast_time <= 0:
		world.wear_hand(player, 1)
	return true


## Whether player may strike target at all. A heart demon is private to its owner, spirits need
## spirit sight (U Minh tempering, Khai Nhãn Phù, a shaken Dao Heart, the Âm Dương boundary), allied
## beasts and peaceful NPCs are never targets. An empty player (an ownerless puppet) sees no spirit.
static func can_target(world, player: Dictionary, target: Dictionary, hand: Dictionary = {}) -> bool:
	if target.is_empty() or float(target.get("health", 0.0)) <= 0.0:
		return false
	var col: String = world.index.collection_of.get(int(target.get("uid", 0)), "")
	if col == "npcs":
		return bool(target.get("hostile", false))
	if col != "creatures" or str(target.get("state", "")) in ["burrow", "dead"] or target.get("ally", false):
		return false
	var owner_peer := -int(player.get("uid", 0)) if not player.is_empty() else 0
	if target.get("private_to_owner", false) and int(target.get("owner_peer", 0)) != owner_peer:
		return false
	if Rules.is_spirit(str(target.kind)):
		if player.is_empty():
			return false
		var sees: bool = str(world.Tempering.get_temper_type(hand)) == "u_minh" \
			or world.Effects.has(player, "pierce_mist") or world.Effects.has(player, "spirit_sight") \
			or float(player.stats.get("dao", 100.0)) < 30.0 or BoundaryDao.in_boundary(player)
		if not sees:
			return false
	return true


## The one path for player-side damage (weapons, skills, puppets) to creatures and hostile NPCs, so
## targeting rules and Boss damage rules hold everywhere. Returns the damage dealt, or -1 if refused.
static func damage_target(world, player: Dictionary, target: Dictionary, damage: float, hand: Dictionary = {}, knockback: float = 0.0) -> float:
	if not can_target(world, player, target, hand):
		return -1.0
	var col: String = world.index.collection_of.get(int(target.uid), "")
	if col == "creatures" and not player.is_empty():
		damage = world.Bosses.modify_incoming_damage(world, target, player, damage, hand)
	target.health = float(target.health) - damage
	target.hit_flash = 0.2
	if col == "npcs":
		if float(target.health) <= 0.0:
			world.Npcs.kill(world, target)
		else:
			world.touch(int(target.uid))
		return damage
	world.Creatures.on_creature_hurt(world, target, player)
	if knockback > 0.0 and not player.is_empty():
		var limit: float = world.map_half() - 1.0
		var away := Vector3(target.position[0] - player.position[0], 0, target.position[2] - player.position[2]).normalized()
		var new_pos := [clampf(target.position[0] + away.x * knockback, -limit, limit), 0.0, clampf(target.position[2] + away.z * knockback, -limit, limit)]
		world.move_entity(target, new_pos, true)
	else:
		world.touch(int(target.uid))
	if float(target.health) <= 0.0:
		kill(world, target)
	return damage


## by_player: the kill was made by a player (or their puppet, skill, effect); only those weigh on
## karma. Predators killing prey is nature.
static func kill(world, target: Dictionary, by_player: bool = true) -> void:
	var cdef = Rules.creature(target.kind)
	if cdef != null:
		Rules.drops(world, cdef.drops, target.position)
	for slot in target.get("stolen", []):
		world.drop_item(slot.id, slot.count, target.position, slot.get("extra", slot))
	target.stolen = []
	# Killing a peaceful beast that never struck first is a sin (GDD 12.1).
	if by_player and cdef != null and cdef.peaceful and not target.get("ally", false) and float(target.get("provoked", 0.0)) <= 0.0:
		world.Karma.add_sin(world, "kill_peaceful")
	if target.get("no_respawn", false) or target.get("ally", false):
		world.remove_entity(target)
		world.log_event("creature_death", {"uid": target.uid})
		return
	target.state = "dead"
	target.respawn = world.day_length() * 2
	world.touch(int(target.uid))
	world.log_event("creature_death", {"uid": target.uid})
