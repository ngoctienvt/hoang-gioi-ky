extends RefCounted

const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")


static func step(world, delta: float) -> void:
	for pid in world.state.players:
		var peer_id := int(pid)
		var player: Dictionary = world.state.players[pid]
		if player.get("ghost", false):
			banish_for_player(world, peer_id)
			continue
		var dao := float(player.stats.get("dao", 100.0))
		var desired := 0
		if str(player.get("character", "")) == "yin_yang":
			if BoundaryDao.in_boundary(player):
				banish_for_player(world, peer_id)
				continue
			desired = 2 if (dao < 15.0 or dao > 85.0) else 1
		else:
			var cursed: bool = world.Effects.has(player, "wanted_curse")
			var spawn_threshold := 50.0 if cursed else 30.0
			var calm_threshold := 55.0 if cursed else 40.0
			if dao > calm_threshold:
				banish_for_player(world, peer_id)
				continue
			if dao < spawn_threshold:
				desired = 2 if dao < 15.0 else 1
		if desired > 0:
			var owned := _owned_demons(world, peer_id)
			while owned.size() < desired:
				var angle: float = float(world.rng.randf()) * TAU
				var pos := [
					clampf(float(player.position[0]) + cos(angle) * 6.0, -world.map_half() + 1.0, world.map_half() - 1.0),
					0.0,
					clampf(float(player.position[2]) + sin(angle) * 6.0, -world.map_half() + 1.0, world.map_half() - 1.0),
				]
				var demon: Dictionary = world.entity("heart_demon", pos)
				demon.merge({
					"owner_peer": peer_id,
					"private_to_owner": true,
					"no_respawn": true,
					"health": 80.0,
					"max_health": 80.0,
					"state": "chase",
					"home": pos.duplicate(),
					"cooldown": 0.0,
					"respawn": 0.0,
					"hit_flash": 0.0,
					"stolen": [],
					"effects": {},
				})
				world.add_entity("creatures", demon)
				owned.append(demon)


static func banish_for_player(world, peer_id: int) -> void:
	for c in _owned_demons(world, peer_id):
		world.remove_entity(c)


static func _owned_demons(world, peer_id: int) -> Array:
	var out: Array = []
	for c in world.state.get("creatures", []):
		if c.kind == "heart_demon" and int(c.get("owner_peer", 0)) == peer_id:
			out.append(c)
	return out


## Creature behaviour of a heart demon: it only hunts its owner and vanishes once the owner is gone
## or dead. Movement is done by the creature step towards ctx.destination.
static func tick_creature(world, creature: Dictionary, definition, ctx: Dictionary) -> void:
	var peer_id := int(creature.get("owner_peer", 0))
	var owner: Dictionary = world.state.players.get(str(peer_id), {})
	if owner.is_empty() or owner.get("ghost", false):
		world.remove_entity(creature)
		ctx.speed = 0.0
		return
	creature.state = "chase"
	ctx.destination = owner.position
	if world.distance(creature.position, owner.position) < 1.8 and float(creature.cooldown) <= 0.0:
		world.hurt(owner, definition.damage)
		creature.cooldown = 1.5
