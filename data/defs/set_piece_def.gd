class_name SetPieceDef
extends Resource

@export var id: StringName = &""
@export var layer_tag: StringName = &"misc"
@export_range(1.0, 32.0) var radius: float = 4.0
## Each entry: {"kind": String, "offset": Vector2, "jitter": float} and, for dens,
## "spawn": creature id living there and "count": how many.
@export var entries: Array[Dictionary] = []
