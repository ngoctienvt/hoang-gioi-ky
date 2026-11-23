## Test mẫu: kiểm tra khung ItemDef và hệ dịch tiếng Việt.
extends GutTest


func test_item_def_defaults() -> void:
	var item := ItemDef.new()
	assert_eq(item.max_stack, 99, "Mặc định chồng được 99")
	assert_true(item.is_stackable(), "Chồng 99 thì stackable")
	assert_eq(item.tool_type, ItemDef.ToolType.NONE)


func test_item_def_tags() -> void:
	var item := ItemDef.new()
	item.tags = {&"fruit": 1.0}
	assert_eq(item.get_tag(&"fruit"), 1.0)
	assert_eq(item.get_tag(&"meat"), 0.0, "Thẻ không có trả về 0")


func test_vietnamese_translation_loaded() -> void:
	TranslationServer.set_locale("vi")
	assert_eq(tr("GAME_TITLE"), "Hoang Giới Ký")
