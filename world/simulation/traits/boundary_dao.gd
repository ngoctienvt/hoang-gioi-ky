extends RefCounted

const MIN_DAO := 35.0
const MAX_DAO := 65.0


static func _bounds(player: Dictionary) -> Array:
	if "yinyang_t1_wide_gate" in player.get("skills", []):
		return [25.0, 75.0]
	return [MIN_DAO, MAX_DAO]


static func in_boundary(player: Dictionary) -> bool:
	if str(player.get("character", "")) != "yin_yang":
		return false
	var dao := float(player.get("stats", {}).get("dao", 100.0))
	var b := _bounds(player)
	return dao >= b[0] and dao <= b[1]


static func outside_boundary(player: Dictionary) -> bool:
	if str(player.get("character", "")) != "yin_yang":
		return false
	var dao := float(player.get("stats", {}).get("dao", 100.0))
	var b := _bounds(player)
	return dao < b[0] or dao > b[1]


static func is_in_shadow(world, player: Dictionary) -> bool:
	if str(world.state.get("clock", {}).get("phase", "day")) != "night":
		return false
	var hand: Dictionary = player.get("inventory", {}).get("equipment", {}).get("hand", {})
	var hand_id := str(hand.get("id", ""))
	if hand_id == "torch" or (hand_id == "hand_warmer" and int(hand.get("durability", 0)) > 0):
		return false
	for s in world.index.entities_near(player.position, 7.0, "structures"):
		if float(s.get("fuel", 0.0)) > 0.0:
			return false
	return true
