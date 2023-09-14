class_name ItemContainer extends Node


# Generic item container which stores items. Used by towers,
# item stash and horadric cube.


signal items_changed()


var _item_list: Array[Item] = []
var _capacity: int


func _init(capacity: int):
	_capacity = capacity


func increase_capacity(new_capacity: int):
	if new_capacity < _capacity:
		push_error("Tried to decrease capacity of item container!")

		return

	_capacity = new_capacity


func have_item_space() -> bool:
	var item_count: int = get_item_count()
	var result: bool = item_count < _capacity

	return result


func can_add_item(_item: Item) -> bool:
	return have_item_space()


func add_item(item: Item, index: int = 0):
	if !have_item_space():
		push_error("Tried to put items over capacity. Use have_item_space() before adding items.")

		return

	_item_list.insert(index, item)
	item.consumed.connect(_on_item_consumed.bind(item))
	add_child(item)
	items_changed.emit()


func remove_item(item: Item):
	if !_item_list.has(item):
		var item_name: String = ItemProperties.get_item_name(item.get_id())
		push_error("Attempted to remove item from item container but it is not in container. Item: ", item_name)

		return

	_item_list.erase(item)
	item.consumed.disconnect(_on_item_consumed)
	remove_child(item)
	items_changed.emit()


# NOTE: important to return a deep copy so that this list
# can be correctly used in code which adds or removes items
# from container.
func get_item_list() -> Array[Item]:
	return _item_list.duplicate()


func get_item_count() -> int:
	var item_count: int = _item_list.size()

	return item_count


func get_capacity() -> int:
	return _capacity


func get_item_index(item: Item) -> int:
	var index: int = _item_list.find(item)

	return index


func get_item_at_index(index: int) -> Item:
	var within_bounds: bool = index < _item_list.size()

	if within_bounds:
		var item: Item = _item_list[index]

		return item
	else:
		return null


func _on_item_consumed(item: Item):
	remove_item(item)
	item.queue_free()
