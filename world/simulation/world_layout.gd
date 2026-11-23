extends RefCounted

const DEFAULT_MAP_SIZE := 288.0
const BIOME_IDS := [
	"bamboo_forest",
	"nether_swamp",
	"crimson_volcano",
	"thunder_gorge",
	"frost_peaks",
	"ancient_ruins",
]


static func warp_xz(x: float, z: float, phase: float) -> Vector2:
	var wx := x + sin(z * 0.045 + phase) * 14.0 + cos((x + z) * 0.028 - phase * 1.7) * 8.0 + sin(z * 0.11 + x * 0.07) * 3.5
	var wz := z + cos(x * 0.045 - phase * 1.3) * 14.0 + sin((x - z) * 0.028 + phase * 0.9) * 8.0 + cos(x * 0.11 - z * 0.07) * 3.5
	return Vector2(wx, wz)


static func generate(seed_value: int, map_size: float = DEFAULT_MAP_SIZE) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7919
	var warp_phase := float(absi(seed_value) % 1000) * 0.01
	var others := ["nether_swamp", "crimson_volcano", "thunder_gorge", "frost_peaks", "ancient_ruins"]
	for i in range(others.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: String = others[i]
		others[i] = others[j]
		others[j] = tmp

	var start_row := rng.randi_range(0, 1)
	var start_idx := start_row * 3 + 1
	var order: Array = []
	var other_idx := 0
	for idx in 6:
		if idx == start_idx:
			order.append("bamboo_forest")
		else:
			order.append(others[other_idx])
			other_idx += 1

	var half := map_size * 0.5
	var cell_w := map_size / 3.0
	var cell_h := map_size / 2.0
	var regions: Array = []
	for row in 2:
		for col in 3:
			var idx := row * 3 + col
			var bid: String = order[idx]
			var base_cx := -half + (col + 0.5) * cell_w
			var base_cz := -half + (row + 0.5) * cell_h
			var cx: float
			var cz: float
			if bid == "bamboo_forest":
				cx = rng.randf_range(-10.0, 10.0)
				cz = rng.randf_range(-10.0, 10.0)
			else:
				cx = clampf(base_cx + rng.randf_range(-14.0, 14.0), -half + 24.0, half - 24.0)
				cz = clampf(base_cz + rng.randf_range(-18.0, 18.0), -half + 24.0, half - 24.0)
				var origin_dist := Vector2(cx, cz).length()
				if origin_dist < 68.0:
					var dir := Vector2(cx, cz).normalized()
					if dir.length_squared() < 0.01:
						dir = Vector2(0.0, -1.0 if row == 0 else 1.0)
					var pushed := dir * 68.0
					cx = clampf(pushed.x, -half + 24.0, half - 24.0)
					cz = clampf(pushed.y, -half + 24.0, half - 24.0)

			var box_r := maxf(cell_w, cell_h) * 0.65
			regions.append({
				"index": idx,
				"col": col,
				"row": row,
				"biome": bid,
				"warp_phase": warp_phase,
				"min_x": clampf(cx - box_r, -half, half),
				"max_x": clampf(cx + box_r, -half, half),
				"min_z": clampf(cz - box_r, -half, half),
				"max_z": clampf(cz + box_r, -half, half),
				"center": [cx, 0.0, cz],
			})
	return regions


static func region_of(regions: Array, pos: Array) -> Dictionary:
	if regions.is_empty() or pos.size() < 3:
		return {}
	var phase := float(regions[0].get("warp_phase", 0.0))
	var w := warp_xz(float(pos[0]), float(pos[2]), phase)
	var best_region: Dictionary = regions[0]
	var best_dist := INF
	for region in regions:
		var c: Array = region.center
		var dx := w.x - float(c[0])
		var dz := w.y - float(c[2])
		var d2 := dx * dx + dz * dz
		if d2 < best_dist:
			best_dist = d2
			best_region = region
	return best_region


static func biome_at(regions: Array, pos: Array) -> String:
	var region := region_of(regions, pos)
	return str(region.get("biome", "bamboo_forest"))
