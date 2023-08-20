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


# NOTE: set item's parent to ItemStash. Items must have a
# valid parent even while they are not in tower inventory
# to ensure that item's cooldown timer is working
# correctly.
func add_item(item: Item, index: int = 0):
	_item_container.add_item(item, index)


func remove_item(item: Item):
	_item_container.remove_item(item)


func get_item_list() -> Array[Item]:
	return _item_container.get_item_list()


func get_item_count() -> int:
	return _item_container.get_item_count()


func get_item_index(item: Item) -> int:
	return _item_container.get_item_index(item)


func _on_item_container_items_changed():
	changed.emit()
