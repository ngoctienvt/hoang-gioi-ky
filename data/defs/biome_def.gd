class_name BiomeDef
extends Resource

@export var id: StringName = &""
@export var name_key: String = ""
@export var ground_color: Color = Color("3b4d38")
@export var accent_color: Color = Color("6b8a5c")
@export var water_type: StringName = &"thanh_moc"
@export var required_pieces: Array[SetPieceDef] = []
@export var optional_pieces: Array[SetPieceDef] = []
@export var optional_weights: PackedFloat32Array = PackedFloat32Array()
@export_range(1, 500) var density: int = 80
@export var den_kinds: Array[StringName] = []
