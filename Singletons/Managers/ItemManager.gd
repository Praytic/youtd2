extends Node


var preloaded_items: Dictionary


func _init():
	var item_id_list: Array = Properties.get_item_id_list()
	
	for item_id in item_id_list:
		var csv_properties: Dictionary = Properties.get_item_csv_properties_by_id(item_id)
		var rarity: String = csv_properties[Item.CsvProperty.RARITY]
		var scene_name: String
		
		match rarity:
			"common": scene_name = "CommonItem"
			"uncommon": scene_name = "UncommonItem"
			"rare": scene_name = "RareItem"
			"unique": scene_name = "UniqueItem"
		
		var item_drop_scene_path: String = "res://Scenes/Items/%s.tscn" % [scene_name]
		var item_drop_scene = load(item_drop_scene_path)
		
		preloaded_items[item_id] = item_drop_scene


func get_item(id: int) -> Item:
	var item = Item.new()
	item.set_id(id)
	return item


# Return new unique instance of the ItemDrop by Item ID. Get
# script for item and attach to scene.
func get_item_drop(id: int) -> ItemDrop:
	var scene: PackedScene = preloaded_items[id]
	var item = scene.instantiate()
	var item_script = load("res://Scenes/Items/ItemDrop.gd")
	item.set_script(item_script)
	item.set_id(id)
	return item
