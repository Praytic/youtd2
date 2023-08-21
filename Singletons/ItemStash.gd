extends Node


# This class represents the item stash. It stores items and
# allows adding/removing items.


signal changed()


var _item_container: ItemContainer


func _ready():
	_item_container = ItemContainer.new(10000)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)

	var test_item_list: Array = Config.test_item_list()

	for item_id in test_item_list:
		var item: Item = Item.make(item_id)
		_item_container.add_item(item)


func _on_item_container_items_changed():
	changed.emit()
