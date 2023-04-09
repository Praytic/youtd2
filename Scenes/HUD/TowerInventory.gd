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

	var index: int = 0


	tooltip_text = "foobar"

	for item in items:
		var item_id: int = item.get_id()
		var item_name: String = Item.get_item_name(item_id)
		_item_list_node.add_item(item_name)
		_item_list_node.set_item_metadata(index, item_id)

		var item_icon: Texture = Item.get_icon(item_id, "S")
		_item_list_node.set_item_icon(index, item_icon)

		var item_tooltip: String = Item.get_tooltip_text(item_id)
		_item_list_node.set_item_tooltip(index, item_tooltip)

		index += 1


func _on_remove_item_button_pressed():
	var selected_items: PackedInt32Array = _item_list_node.get_selected_items()

	if selected_items.is_empty():
		return

	var selected_index: int = selected_items[0]
	var item_id: int = _item_list_node.get_item_metadata(selected_index)

	_tower.remove_item(item_id)
