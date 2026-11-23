## Định nghĩa điểm tài nguyên trên bản đồ (cây, tảng đá, bụi cỏ...).
## File .tres trong data/nodes/.
class_name ResourceNodeDef
extends Resource

@export var id: StringName = &""
@export var name_key: String = ""
## Công cụ cần để khai thác. NONE = nhặt bằng tay.
@export var required_tool: ItemDef.ToolType = ItemDef.ToolType.NONE
## Các giai đoạn theo thứ tự, ví dụ cây: đứng -> đổ -> gốc.
@export var stages: Array[ResourceNodeStage] = []
## Giây để mọc lại sau khi khai thác hết. 0 = không mọc lại.
@export_range(0.0, 99999.0) var regrow_time: float = 0.0
