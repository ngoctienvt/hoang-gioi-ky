extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

static func attack(world, player: Dictionary, args: Dictionary) -> bool:
	if player.attack_cd > 0:
		return false
	var target = world.find_any(args.get("uid", -1))
	var peer = args.get("peer_id", -int(args.get("uid", 1)) if args.get("uid", 1) is int else -1)
	var other = world.state.players.get(str(peer), {})
	if not other.is_empty():
		if not player.get("mad", false) or other == player or other.ghost:
			return false
		target = other
	if target.is_empty() or not world.near(player, target, 2.8):
		return false
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	var damage = 15.0 if hand.is_empty() else maxf(15, float(world.item(hand.id).get("damage", 15)))
	if player.beast_time > 0:
		damage = 35.0
	if not other.is_empty():
		world.hurt(other, damage)
	elif target in world.state.creatures:
		if target.health <= 0 or target.state == "burrow":
			return false
		target.health -= damage
		target.state = "flee" if target.kind == "monkey" else "chase"
		target.hit_flash = 0.2
		var away = Vector3(target.position[0] - player.position[0], 0, target.position[2] - player.position[2]).normalized()
		target.position[0] = clampf(target.position[0] + away.x * 0.4, -39, 39)
		target.position[2] = clampf(target.position[2] + away.z * 0.4, -39, 39)
		if target.health <= 0:
			kill(world, target)
	elif target in world.state.structures:
		if not world.has_tool(player, "hammer"):
			return false
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
						var count = int(value.ingredients[id]) / 2
						if count > 0:
							world.drop_item(str(id), count, target.position)
					break
			world.state.structures.erase(target)
	else:
		return false
	player.attack_cd = 0.65
	if int(hand.get("vitality_hits", 0)) > 0:
		hand.vitality_hits -= 1
		player.stats.health = minf(float(player.stats.get("max_health", 150)), player.stats.health + 2)
	if player.beast_time <= 0:
		world.wear_hand(player, 1)
	return true

static func kill(world, target: Dictionary) -> void:
	Rules.drops(world, Rules.creature(target.kind).drops, target.position)
	for slot in target.stolen:
		world.drop_item(slot.id, slot.count, target.position, slot.get("extra", slot))
	target.stolen = []
	target.state = "dead"
	target.respawn = world.day_length() * 2
	world.log_event("creature_death", {"uid": target.uid})
