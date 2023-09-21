class_name ItemContainer extends Node


# Generic item container which stores items. Used by towers,
# item stash and horadric cube.


signal items_changed()


var _item_list: Array[Item] = []
var _capacity: int
var _fixed_capacity: bool


func _init(capacity: int, fixed_capacity = false):
	_capacity = capacity
	_fixed_capacity = fixed_capacity
	if fixed_capacity:
		_item_list.resize(capacity)


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

	# If we will try to insert an item to an index greater than size(),
	# the insert will be silently ignored. So need to set it to the last
	# available position.
	if not _fixed_capacity and index > _item_list.size():
		index = _item_list.size()
	
	_item_list.insert(index, item)
	item.consumed.connect(_on_item_consumed.bind(item))
	add_child(item)
	items_changed.emit()


func remove_item(item: Item):
	if !_item_list.has(item):
		var item_name: String = ItemProperties.get_item_name(item.get_id())
		push_error("Attempted to remove item from item container but it is not in container. Item: ", item_name)

		return

	if _fixed_capacity:
		var erase_index = _item_list.find(item)
		if erase_index != -1:
			_item_list[erase_index] = null
	else:
		_item_list.erase(item)
	item.consumed.disconnect(_on_item_consumed)
	remove_child(item)
	items_changed.emit()


# NOTE: important to return a deep copy so that this list
# can be correctly used in code which adds or removes items
# from container.
func get_item_list(rarity_filter = null, type_filter = null) -> Array[Item]:
	var item_list: Array[Item]
	for item in _item_list.duplicate():
		if item == null and _fixed_capacity:
			item_list.append(null)
		else:
			var rarity = item.get_rarity() == rarity_filter or rarity_filter == null
			var type = item.get_item_type() == type_filter or type_filter == null
			if rarity and type:
				item_list.append(item)
	return item_list


func get_item_count(rarity_filter = null, type_filter = null) -> int:
	var item_count: int
	var item_list = get_item_list(rarity_filter, type_filter)
	if _fixed_capacity:
		item_count = item_list.size() - item_list.count(null) 
	else:
		item_count = item_list.size()
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
