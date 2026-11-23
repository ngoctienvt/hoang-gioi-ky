## Định nghĩa một mùa trong năm (Thu, Đông, Xuân, Hạ). File .tres trong data/seasons/.
class_name SeasonDef
extends Resource

@export var id: StringName = &""
@export var name_key: String = ""
@export_range(1, 365) var default_length: int = 20
@export_range(0, 16) var day_segments: int = 8
@export_range(0, 16) var dusk_segments: int = 6
@export_range(0, 16) var night_segments: int = 2
@export var base_temperature: float = 50.0
@export_range(0.0, 1.0) var rain_chance: float = 0.2
@export_range(0.0, 1.0) var snow_chance: float = 0.0
@export_range(0.0, 1.0) var storm_chance: float = 0.05
@export var sky_tint: Color = Color(0.88, 0.76, 0.6, 1.0)
