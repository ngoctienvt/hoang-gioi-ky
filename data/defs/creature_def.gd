## Định nghĩa một loài yêu thú. File .tres trong data/creatures/.
class_name CreatureDef
extends Resource

## Khoảng thời gian trong ngày mà loài này hoạt động.
enum ActivePeriod { ALWAYS, DAY, DUSK, NIGHT, DUSK_AND_NIGHT }

@export var id: StringName = &""
@export var name_key: String = ""
@export var scene: PackedScene
@export_range(1.0, 9999.0) var max_health: float = 50.0
@export_range(0.0, 999.0) var damage: float = 0.0
@export_range(0.0, 50.0) var move_speed: float = 3.0
## Tầm phát hiện người chơi (mét).
@export_range(0.0, 100.0) var detect_range: float = 8.0
@export var active_period: ActivePeriod = ActivePeriod.ALWAYS
@export var behavior: StringName = &"herd_flee"
@export var params: Dictionary = {}
@export var drops: Array[DropEntry] = []
