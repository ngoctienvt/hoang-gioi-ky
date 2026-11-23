extends Node3D
## Cảnh xem asset: tự nạp mọi GLB trong res://assets/models (trừ _placeholder), xếp hàng ngang,
## mỗi món kèm hình nhân 1,7 m và nhãn tên/kích thước. Camera quay quanh để zoom kiểm tra.
## Điều khiển in ở góc trái màn hình.

const ROOT := "res://assets/models"
const GAP := 1.2

var items: Array = []        # {node, name, aabb, anim, clips, clip_i, ref}
var cur := 0
var yaw := deg_to_rad(-25.0)
var pitch := deg_to_rad(-50.0)
var dist := 6.0
var target := Vector3.ZERO
var cam: Camera3D
var hud: Label
var sun: DirectionalLight3D
var env: Environment
var neutral := false
var refs_on := true
var dragging := 0  # 1 xoay, 2 dời

func _ready() -> void:
	_build_world()
	var files: Array[String] = []
	_scan(ROOT, files)
	files.sort()
	var nodes: Array = []
	for f in files:
		var ps := load(f) as PackedScene
		if ps == null:
			continue
		var n := ps.instantiate() as Node3D
		add_child(n)
		nodes.append([n, f])
	# đợi skin đăng ký với skeleton rồi mới đo được mesh có xương
	await get_tree().process_frame
	await get_tree().process_frame
	var x := 0.0
	for pair in nodes:
		var n: Node3D = pair[0]; var f: String = pair[1]
		var bb := _aabb(n)
		x += bb.size.x * 0.5
		n.position = Vector3(x - bb.get_center().x, 0, -bb.get_center().z)  # giữ nguyên pivot để lộ lỗi lơ lửng hoặc lún
		var ref := _make_ref(Vector3(x + bb.size.x * 0.5 + 0.45, 0.85, 0))
		var lb := Label3D.new()
		lb.text = "%s\n%.2f × %.2f × %.2f m   đáy y=%.2f" % [f.get_file().get_basename(), bb.size.x, bb.size.y, bb.size.z, bb.position.y]
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.font_size = 40; lb.pixel_size = 0.0012 * clampf(bb.size.y, 0.4, 4.0); lb.outline_size = 10
		lb.position = Vector3(x, bb.size.y + 0.12 + bb.size.y * 0.08, 0)
		add_child(lb)
		var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var clips: Array = []
		if ap:
			for c in ap.get_animation_list():
				if c != "RESET": clips.append(c)
			if "idle" in clips: ap.play("idle")
		items.append({"node": n, "name": f.get_file().get_basename(), "path": f, "aabb": bb,
			"anim": ap, "clips": clips, "clip_i": clips.find("idle"), "ref": ref, "x": x,
			"lift": bb.position.y})
		x += bb.size.x * 0.5 + 0.9 + GAP
	_focus(0)

func _scan(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null: return
	for sub in d.get_directories():
		if not sub.begins_with("_"): _scan(dir.path_join(sub), out)
	for f in d.get_files():
		if f.ends_with(".glb"): out.append(dir.path_join(f))

func _aabb(n: Node) -> AABB:
	var acc := AABB(); var first := true
	for m in n.find_children("*", "VisualInstance3D", true, false):
		var vi := m as VisualInstance3D
		var b: AABB = vi.global_transform * vi.get_aabb()
		var mi := vi as MeshInstance3D
		var sr: SkinReference = mi.get_skin_reference() if mi else null
		if mi and mi.skin and sr and sr.get_skeleton().is_valid():
			# mesh có xương: đo trên tư thế đang hiển thị, không phải bind pose
			var baked := mi.bake_mesh_from_current_skeleton_pose()
			if baked: b = mi.global_transform * baked.get_aabb()
		if first: acc = b; first = false
		else: acc = acc.merge(b)
	return acc

func _make_ref(p: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new(); cm.radius = 0.22; cm.height = 1.7
	var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.75, 0.75, 0.8, 0.55)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.material = mt; mi.mesh = cm; mi.position = p
	add_child(mi)
	return mi

func _build_world() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.22, 0.22, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.41, 0.46); env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 0.9
	env.adjustment_enabled = true; env.adjustment_contrast = 1.1; env.adjustment_saturation = 0.78
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = Color(0.88, 0.76, 0.6); sun.light_energy = 0.95; sun.shadow_enabled = true
	add_child(sun)
	var g := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(400, 400)
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.31, 0.33, 0.21); gm.roughness = 1.0
	pm.material = gm; g.mesh = pm; add_child(g)
	# lưới 1 m
	var im := ImmediateMesh.new(); var gl := MeshInstance3D.new(); gl.mesh = im
	var lm := StandardMaterial3D.new(); lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0, 0, 0, 0.18); lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	im.surface_begin(Mesh.PRIMITIVE_LINES, lm)
	for i in range(-20, 61):
		im.surface_add_vertex(Vector3(i, 0.005, -20)); im.surface_add_vertex(Vector3(i, 0.005, 20))
	for j in range(-20, 21):
		im.surface_add_vertex(Vector3(-20, 0.005, j)); im.surface_add_vertex(Vector3(60, 0.005, j))
	im.surface_end(); add_child(gl)
	cam = Camera3D.new(); cam.fov = 45; cam.near = 0.02; add_child(cam); cam.current = true
	hud = Label.new(); hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 17)
	hud.add_theme_color_override("font_outline_color", Color.BLACK); hud.add_theme_constant_override("outline_size", 6)
	var cl := CanvasLayer.new(); cl.add_child(hud); add_child(cl)

func _focus(i: int) -> void:
	if items.is_empty(): return
	cur = wrapi(i, 0, items.size())
	var it: Dictionary = items[cur]
	var bb: AABB = it.aabb
	target = Vector3(it.x, bb.size.y * 0.45, 0)
	dist = clamp(maxf(bb.get_longest_axis_size(), 1.7) * 2.4, 1.5, 40.0)
	yaw = deg_to_rad(-25); pitch = deg_to_rad(-35)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed: dist = max(0.15, dist * 0.88)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed: dist = min(80.0, dist * 1.14)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = 1 if mb.pressed else 0
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = 2 if mb.pressed else 0
	elif e is InputEventMouseMotion and dragging:
		var r := (e as InputEventMouseMotion).relative
		if dragging == 1 and not Input.is_key_pressed(KEY_SHIFT):
			yaw -= r.x * 0.006; pitch = clamp(pitch - r.y * 0.006, deg_to_rad(-89), deg_to_rad(10))
		else:
			var b := cam.global_transform.basis
			target += (-b.x * r.x + b.y * r.y) * dist * 0.0015
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9: _focus(k - KEY_1)
		elif k == KEY_TAB: _focus(cur + (-1 if Input.is_key_pressed(KEY_SHIFT) else 1))
		elif k == KEY_F: _focus(cur)
		elif k == KEY_SPACE: _next_clip(1)
		elif k == KEY_BACKSPACE: _next_clip(-1)
		elif k == KEY_L:
			neutral = not neutral
			sun.light_color = Color.WHITE if neutral else Color(0.88, 0.76, 0.6)
			sun.light_energy = 1.3 if neutral else 0.95
			env.adjustment_saturation = 1.0 if neutral else 0.78
		elif k == KEY_H:
			refs_on = not refs_on
			for it in items: it.ref.visible = refs_on
		elif k == KEY_G:  # góc camera game
			yaw = deg_to_rad(-25); pitch = deg_to_rad(-50)
		elif k == KEY_ESCAPE: get_tree().quit()

func _next_clip(d: int) -> void:
	var it: Dictionary = items[cur]
	if it.anim == null or it.clips.is_empty(): return
	it.clip_i = wrapi(it.clip_i + d, 0, it.clips.size())
	(it.anim as AnimationPlayer).play(it.clips[it.clip_i])

func _process(dt: float) -> void:
	var mv := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.z += 1
	if Input.is_key_pressed(KEY_Q): mv.y -= 1
	if Input.is_key_pressed(KEY_E): mv.y += 1
	if mv != Vector3.ZERO:
		target += Basis(Vector3.UP, yaw) * mv * dist * 0.8 * dt
	var off := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Vector3(0, 0, dist)
	cam.global_position = target + off
	cam.look_at(target, Vector3.UP)
	if items.is_empty():
		hud.text = "Chưa có GLB nào trong %s" % ROOT; return
	var it: Dictionary = items[cur]
	var bb: AABB = it.aabb
	var clip := "-" if it.clips.is_empty() or it.clip_i < 0 else "%s (%d/%d)" % [it.clips[it.clip_i], it.clip_i + 1, it.clips.size()]
	hud.text = "[%d/%d] %s   %.2f × %.2f × %.2f m   hoạt ảnh: %s\n" % [cur + 1, items.size(), it.name, bb.size.x, bb.size.y, bb.size.z, clip] \
		+ "Chuột trái/phải kéo: xoay  ·  Shift+kéo hoặc chuột giữa: dời  ·  Lăn: zoom  ·  WASD/QE: di chuyển\n" \
		+ "1-9 / Tab: chọn món  ·  F: căn lại  ·  G: góc camera game  ·  Space/Backspace: đổi hoạt ảnh\n" \
		+ "L: ánh sáng game/trung tính  ·  H: ẩn/hiện hình nhân 1,7 m  ·  Esc: thoát"
