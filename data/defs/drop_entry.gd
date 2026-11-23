## Một dòng đồ rơi: vật phẩm, khoảng số lượng và tỉ lệ rơi.
## Dùng chung cho điểm tài nguyên và yêu thú.
class_name DropEntry
extends Resource

@export var item: ItemDef
@export_range(1, 99) var min_count: int = 1
@export_range(1, 99) var max_count: int = 1
## Tỉ lệ rơi, 0..1.
@export_range(0.0, 1.0) var chance: float = 1.0
