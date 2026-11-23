## Một giai đoạn của điểm tài nguyên (ví dụ "cây đứng"), kèm số nhát và đồ rơi.
class_name ResourceNodeStage
extends Resource

@export var stage_name: StringName = &""
## Số nhát công cụ để qua giai đoạn này.
@export_range(1, 99) var work_hits: int = 1
## Cảnh hiển thị cho giai đoạn này (có thể để trống ở bản demo).
@export var scene: PackedScene
@export var drops: Array[DropEntry] = []
