extends RefCounted
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
	elif col == "creatures":
		if target.health <= 0 or target.state == "burrow":
			return false
		if target.get("private_to_owner", false) and int(target.get("owner_peer", 0)) != -int(player.uid):
			return false
		if target.kind in ["wraith", "phantom"]:
			var ttype: String = str(world.Tempering.get_temper_type(hand))
			var can_see_spirit: bool = ttype == "u_minh" or world.Effects.has(player, "pierce_mist") or world.Effects.has(player, "spirit_sight") or float(player.stats.get("dao", 100.0)) < 30.0 or BoundaryDao.in_boundary(player)
			if not can_see_spirit:
				return false
		damage = world.Bosses.modify_incoming_damage(world, target, player, damage, hand)
		target.health -= damage
		if player.beast_time > 0 and world.Skills.has_skill(player, "beast_t2_bloodlust"):
			player.stats["health"] = minf(float(player.stats.get("max_health", 150.0)), float(player.stats.get("health", 0.0)) + damage * 0.15)
		world.Creatures.on_creature_hurt(world, target, player)
		world.Creatures.notify_noise(world, player.position, 8.0)
		target.hit_flash = 0.2
		world.Tempering.apply_hit(world, player, target, hand)
		var limit: float = world.map_half() - 1.0
		var away := Vector3(target.position[0] - player.position[0], 0, target.position[2] - player.position[2]).normalized()
		var new_pos := [clampf(target.position[0] + away.x * 0.4, -limit, limit), 0.0, clampf(target.position[2] + away.z * 0.4, -limit, limit)]
		world.move_entity(target, new_pos, true)
		if target.health <= 0:
			kill(world, target)
	elif col == "npcs":
		if float(target.get("health", 0.0)) <= 0.0 or not target.get("hostile", false):
			return false
		target.health = float(target.health) - damage
		target.hit_flash = 0.2
		world.Tempering.apply_hit(world, player, target, hand)
		if float(target.health) <= 0.0:
			world.Npcs.kill(world, target)
		else:
			world.touch(int(target.uid))
	elif col == "structures":
		if not world.has_tool(player, "hammer"):
			return false
		world.Creatures.notify_noise(world, player.position, 8.0)
		target.health -= damage
		if target.health <= 0:
			for slot in target.slots:
				if not slot.is_empty():
					world.drop_item(slot.id, slot.count, target.position, slot)
			for id in target.ingredients:
				world.drop_item(id, 1, target.position)
			if target.output != "":
				world.drop_item(target.output, 1, target.position)
			if target.solvent != "":
				world.drop_item(target.solvent, 1, target.position)
			for value in RecipeDB.recipes.values():
				if value.is_structure and str(value.result.id) == target.kind:
					for id in value.ingredients:
						var count := int(value.ingredients[id]) / 2
						if count > 0:
							world.drop_item(str(id), count, target.position)
					break
			world.remove_entity(target)
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


static func kill(world, target: Dictionary) -> void:
	var cdef = Rules.creature(target.kind)
	if cdef != null:
		Rules.drops(world, cdef.drops, target.position)
	for slot in target.get("stolen", []):
		world.drop_item(slot.id, slot.count, target.position, slot.get("extra", slot))
	target.stolen = []
	if target.kind == "rabbit" and not target.get("ally", false):
		world.Karma.add_sin(world, "kill_peaceful")
	if target.get("no_respawn", false) or target.get("ally", false):
		world.remove_entity(target)
		world.log_event("creature_death", {"uid": target.uid})
		return
	target.state = "dead"
	target.respawn = world.day_length() * 2
	world.touch(int(target.uid))
	world.log_event("creature_death", {"uid": target.uid})
