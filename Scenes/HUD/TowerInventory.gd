extends Control


var _tower: Tower = null

@onready var _item_list_node: ItemList = $PanelContainer/VBoxContainer/ItemList


func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	var new_tower: Tower = tower
	_tower = new_tower

	if prev_tower != null:
		prev_tower.items_changed.disconnect(on_tower_items_changed)

	if new_tower != null:
		new_tower.items_changed.connect(on_tower_items_changed)
		on_tower_items_changed()


func on_tower_items_changed():
	_item_list_node.clear()

	var items: Array[Item] = _tower.get_items()

	for item in items:
		var item_name: String = item.get_item_name()
		_item_list_node.add_item(item_name)
