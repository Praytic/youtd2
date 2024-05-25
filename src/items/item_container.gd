class_name ItemContainer extends Node


# Generic item container which stores items. Used by towers,
# item stash and horadric cube.


signal items_changed()


var _item_list: Array[Item] = []
var _item_list_with_slots: Array[Item] = []
var _item_to_index_map: Dictionary = {}
@export var _capacity: int = 0

static var _uid_max: int = 1
var _uid: int = 0


#########################
###     Built-in      ###
#########################

func _ready():
	_uid = _uid_max
	ItemContainer._uid_max += 1
	GroupManager.add("item_containers", self, get_uid())
	
	set_capacity(_capacity)


#########################
###       Public      ###
#########################

func get_uid() -> int:
	return _uid


func set_capacity(new_capacity: int):
	if new_capacity < _capacity:
		push_error("Tried to decrease capacity of item container!")

		return

	_capacity = new_capacity
	_item_list_with_slots.resize(new_capacity)


func have_item_space() -> bool:
	var item_count: int = get_item_count()
	var result: bool = item_count < _capacity

	return result


func can_add_item(_item: Item) -> bool:
	return have_item_space()


func add_item(item: Item, insert_index: int = -1):
	if !have_item_space():
		push_error("Tried to put items over capacity. Use have_item_space() before adding items.")

		return
	
#	If no index was defined, find first free slot
	if insert_index == -1:
		for i in range(0, _item_list_with_slots.size()):
			var slot_is_free: bool = _item_list_with_slots[i] == null
			
			if slot_is_free:
				insert_index = i
				
				break
		
		var failed_to_find_free_index: bool = insert_index == -1
		if failed_to_find_free_index:
			push_error("Failed to find free index.")
			
			return
	
	_item_list.append(item)
	_item_list_with_slots[insert_index] = item
	_item_to_index_map[item] = insert_index

	item.consumed.connect(_on_item_consumed.bind(item))
	add_child(item)
	items_changed.emit()


func remove_item(item: Item):
	var item_index: int = get_item_index(item)
	var item_not_found: bool = item_index == -1
	
	if item_not_found:
		var item_name: String = ItemProperties.get_item_name(item.get_id())
		push_error("Attempted to remove item from item container but it is not in container. Item: ", item_name)

		return
	
	_item_list.erase(item)
	_item_list_with_slots[item_index] = null
	_item_to_index_map.erase(item)
	item.consumed.disconnect(_on_item_consumed)
	if item.is_inside_tree():
		remove_child(item)
	items_changed.emit()


func has(item: Item) -> bool:
	var has_item: bool = _item_to_index_map.has(item)

	return has_item


func get_item_list_with_slots() -> Array[Item]:
	return _item_list_with_slots


func get_item_list(rarity_filter: Array = [], type_filter: Array = []) -> Array[Item]:
	var filtered_list: Array[Item] = Utils.filter_item_list(_item_list, rarity_filter, type_filter)

	return filtered_list


func get_item_count(rarity_filter: Array = [], type_filter: Array = []) -> int:
	var item_count: int = get_item_list(rarity_filter, type_filter).size()

	return item_count


func get_capacity() -> int:
	return _capacity


func get_item_index(item: Item) -> int:
	var index: int = _item_to_index_map.get(item, -1)

	return index


func get_item_at_index(index: int) -> Item:
	var within_bounds: bool = index < _item_list_with_slots.size()

	if within_bounds:
		var item: Item = _item_list_with_slots[index]

		return item
	else:
		return null


func clear():
	for item in _item_list_with_slots:
		remove_child(item)
		item.queue_free()

	_item_list.clear()
	_item_list_with_slots.clear()


#########################
###     Callbacks     ###
#########################

func _on_item_consumed(item: Item):
	remove_item(item)
	item.queue_free()
