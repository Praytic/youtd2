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
var _highest_index: int = 0
var _player: Player = null


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

func set_player(player: Player):
	_player = player


func get_player() -> Player:
	return _player


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

	if insert_index > _highest_index:
		_highest_index = insert_index

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


# NOTE: this f-n returns a contiguous item list without
# empty slots. The order of this list doesn't match the real
# order. To get items in real order, iterate over indexes
# and use get_item_at_index().
func get_item_list() -> Array[Item]:
	return _item_list.duplicate()


func get_item_count() -> int:
	var item_count: int = _item_list.size()

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


# Returns highest occupied index (ever). This value doesn't
# decrease if items are removed.
func get_highest_index() -> int:
	return _highest_index


func sort_items_by_rarity_and_levels():
	var new_item_list: Array[Item] = []
	var new_item_list_with_slots: Array[Item] = []
	new_item_list_with_slots.resize(_item_list_with_slots.size())
	var new_item_to_index_map: Dictionary = {}
	
	var _sorting_func = func(item1: Item, item2: Item):
		var rarity1: int = item1.get_rarity()
		var rarity2: int = item2.get_rarity()
		
		if rarity1 < rarity2:
			return true
		if rarity2 < rarity1:
			return false
		
		# == case:
		var level1: int = item1.get_required_wave_level()
		var level2: int = item2.get_required_wave_level()
		
		if level1 < level2:
			return true
		if level2 < level1:
			return false
			
		# == case:
		var id1: int = item1.get_id()
		var id2: int = item2.get_id()
		
		if id1 <= id2:
			return true
		return false
	
	_item_list.sort_custom(_sorting_func)
	
	var index: int = 0
	for item in _item_list:
		new_item_list_with_slots[index] = item
		new_item_to_index_map[item] = index
		index += 1
		
	_item_list_with_slots = new_item_list_with_slots
	_item_to_index_map = new_item_to_index_map
	items_changed.emit()

#########################
###     Callbacks     ###
#########################

func _on_item_consumed(item: Item):
	remove_item(item)
	item.queue_free()
