extends Control
## Crisp Minimap widget (no truncated labels) with click-to-expand signal for Full World Map.

signal expand_requested

const Layout = preload("res://world/simulation/world_layout.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

var regions: Array = []
var teleports: Array = []
var players: Dictionary = {}
var local_id := 1
var map_size := 288.0
var biome_colors: Dictionary = {}
var map_texture: ImageTexture
var baked_sig := ""
var show_labels := false


func _ready() -> void:
	custom_minimum_size = Vector2(168, 110)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = tr("HUD_MINIMAP_HINT")
	for bid in ["bamboo_forest", "nether_swamp", "crimson_volcano", "thunder_gorge", "frost_peaks", "ancient_ruins"]:
		var path := "res://data/biomes/%s.tres" % bid
		if ResourceLoader.exists(path):
			var bdef: BiomeDef = load(path)
			if bdef != null:
				biome_colors[bid] = bdef.ground_color


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		expand_requested.emit()
		accept_event()


func update_map(state: Dictionary, peer_id: int) -> void:
	regions = state.get("regions", [])
	teleports = state.get("teleports", [])
	players = state.get("players", {})
	local_id = peer_id
	map_size = maxf(1.0, float(state.get("options", {}).get("map_size", 288.0)))
	var sig := str(state.get("seed", 0)) + ":" + str(regions.size())
	if sig != baked_sig and not regions.is_empty():
		baked_sig = sig
		_bake_map_texture()
	queue_redraw()


func _bake_map_texture() -> void:
	var w := 120
	var h := 80
	var half := map_size * 0.5
	var grid: Array = []
	grid.resize(w * h)
	for y in h:
		var wz := -half + (float(y) + 0.5) / float(h) * map_size
		for x in w:
			var wx := -half + (float(x) + 0.5) / float(w) * map_size
			grid[y * w + x] = Layout.biome_at(regions, [wx, 0.0, wz])

	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var bid: String = grid[y * w + x]
			var col: Color = biome_colors.get(bid, Color("3f523a"))
			var is_border: bool = (x + 1 < w and grid[y * w + x + 1] != bid) or (y + 1 < h and grid[(y + 1) * w + x] != bid)
			if is_border:
				col = col.darkened(0.36)
			img.set_pixel(x, y, col)
	map_texture = ImageTexture.create_from_image(img)


func _to_minimap(pos: Array) -> Vector2:
	var half := map_size * 0.5
	var nx := (float(pos[0]) + half) / map_size
	var nz := (float(pos[2]) + half) / map_size
	return Vector2(clampf(nx, 0.0, 1.0) * size.x, clampf(nz, 0.0, 1.0) * size.y)


func _draw() -> void:
	if map_texture != null:
		draw_texture_rect(map_texture, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), UITheme.BORDER_GOLD_DIM, false, 1.0)

	if show_labels:
		var font := get_theme_font("font")
		for region in regions:
			var bid := str(region.get("biome", "bamboo_forest"))
			var pt := _to_minimap(region.get("center", [0.0, 0.0, 0.0]))
			var label := tr("BIOME_" + bid.to_upper())
			var l_sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
			var pos := Vector2(clampf(pt.x - l_sz.x * 0.5, 8.0, size.x - l_sz.x - 8.0), clampf(pt.y + 4.0, 18.0, size.y - 8.0))
			draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(0.02, 0.03, 0.03, 0.92))
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.TEXT_PRIMARY)

	var tp_r := 5.0 if show_labels else 3.2
	for tp in teleports:
		var pt := _to_minimap(tp.get("position", [0.0, 0.0, 0.0]))
		var active := str(tp.get("state", "dormant")) == "active"
		var col := Color("5cd6c8") if active else Color("8a8a92")
		draw_circle(pt, tp_r + 1.2, Color(0.03, 0.05, 0.05, 0.85))
		draw_circle(pt, tp_r, col)

	var p_r := 5.5 if show_labels else 3.6
	for pid in players:
		var p: Dictionary = players[pid]
		var pt := _to_minimap(p.get("position", [0.0, 0.0, 0.0]))
		if int(pid) == local_id:
			draw_circle(pt, p_r + 2.0, Color("141e1c"))
			draw_circle(pt, p_r, Color("ffdf7a"))
		else:
			draw_circle(pt, p_r, Color("7be38b"))
