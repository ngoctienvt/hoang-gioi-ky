extends Node

const ITEMS_DIR: String = "res://data/items/"
var items: Dictionary = {}

func _ready() -> void:
	reload_data()

func reload_data() -> void:
	items.clear()
	for file in DirAccess.get_files_at(ITEMS_DIR):
		if file.ends_with(".tres"):
			var item = load(ITEMS_DIR + file) as ItemDef
			if item != null and not item.id.is_empty():
				items[String(item.id)] = item
			else:
				push_error("[ItemDB] Invalid resource: " + file)
	print("[ItemDB] Loaded %d items" % items.size())

func get_item(id: String) -> ItemDef:
	return items.get(id)
