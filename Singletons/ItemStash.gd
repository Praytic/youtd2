extends Node


# This class represents the item stash. It stores items and
# allows adding/removing items.


signal changed()


var _item_list: Array[Item] = []


func _ready():
	var test_item_list: Array = Config.test_item_list()

	for item_id in test_item_list:
		var item: Item = Item.make(item_id)
		add_item(item)


# NOTE: set item's parent to ItemStash. Items must have a
# valid parent even while they are not in tower inventory
# to ensure that item's cooldown timer is working
# correctly.
func add_item(item: Item, index: int = 0):
	_item_list.insert(index, item)
	item.consumed.connect(_on_item_consumed.bind(item))
	add_child(item)
	changed.emit()


func remove_item(item: Item):
	if !_item_list.has(item):
		var item_name: String = ItemProperties.get_item_name(item.get_id())
		push_error("Attempted to remove item from stash but is not in stash. Item: ", item_name)

		return

	_item_list.erase(item)
	item.consumed.disconnect(_on_item_consumed)
	remove_child(item)
	changed.emit()


func get_item_list() -> Array[Item]:
	return _item_list.duplicate()


func get_item_count() -> int:
	var item_count: int = _item_list.size()

	return item_count


func get_item_index(item: Item) -> int:
	var index: int = _item_list.find(item)

	return index


func _on_item_consumed(item: Item):
	_item_list.erase(item)
	changed.emit()
