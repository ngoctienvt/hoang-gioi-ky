extends CharacterBody3D
## Host-only collision body for one player. Its position is copied into the world state and reaches
## clients through state replication; clients never create avatars.
var peer_id := 1
var direction := Vector2.ZERO
var speed := 5.0
var ghost := false
var input_age := 0.0
var map_limit := 0.0  # set by the session from the world's map size
var in_secret_realm := false

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)

func _physics_process(delta: float) -> void:
	input_age += delta
	if input_age > 0.4:
		direction = Vector2.ZERO
	velocity = Vector3(direction.x, 0, direction.y) * speed
	move_and_slide()
	if in_secret_realm:
		position.x = clampf(position.x, 1200.0 - 16.0, 1200.0 + 16.0)
		position.z = clampf(position.z, 1200.0 - 16.0, 1200.0 + 16.0)
	else:
		position.x = clampf(position.x, -map_limit, map_limit)
		position.z = clampf(position.z, -map_limit, map_limit)
	position.y = 0.0
