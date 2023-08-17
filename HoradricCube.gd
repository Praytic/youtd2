extends Node


signal items_changed()
signal item_was_removed()


const CAPACITY: int = 5


var _item_list: Array[Item] = []

var _2_oils: Dictionary = {
	ItemType.enm.REGULAR: 0,
	ItemType.enm.OIL: 2,
}

var _4_oils: Dictionary = {
	ItemType.enm.REGULAR: 0,
	ItemType.enm.OIL: 4,
}

var _3_regular: Dictionary = {
	ItemType.enm.REGULAR: 3,
	ItemType.enm.OIL: 0,
}

var _5_regular: Dictionary = {
	ItemType.enm.REGULAR: 5,
	ItemType.enm.OIL: 0,
}


func have_space() -> bool:
	var item_count: int = _item_list.size()

	return item_count < CAPACITY


# Called every frame. 'delta' is the elapsed time since the previous frame.
func add_item(item: Item) -> bool:
	var item_id: int = item.get_id()
	var item_type: ItemType.enm = ItemProperties.get_type(item_id)
	var is_consumable: bool = item_type == ItemType.enm.CONSUMABLE

	if is_consumable:
		Messages.add_error("Cannot add consumables to Horadric Cube.")

		return false

	if !have_space():
		push_error("Tried to put items over capacity. Use HoradricCube.have_space() before adding items.")

		return false

	_item_list.append(item)

	if item.get_parent() != null:
		item.reparent(self)
	else:
		add_child(item)

	items_changed.emit()

	return true


func remove_item(item: Item):
	_item_list.erase(item)
	remove_child(item)
#	NOTE: this signal moves item back to item stash
	item_was_removed.emit(item)
	items_changed.emit()


func get_items() -> Array[Item]:
	return _item_list.duplicate()


func can_transmute() -> bool:
	var all_recipes: Array = [
		_2_oils,
		_4_oils,
		_3_regular,
		_5_regular,
	]

	var current_recipe: Dictionary = _get_current_recipe()
	var recipe_is_valid: bool = all_recipes.has(current_recipe)
	
	return recipe_is_valid


func _get_current_recipe() -> Dictionary:
	var count_map: Dictionary = {
		ItemType.enm.REGULAR: 0,
		ItemType.enm.OIL: 0,
	}

	for item in _item_list:
		var item_id: int = item.get_id()
		var item_type: ItemType.enm = ItemProperties.get_type(item_id)
		count_map[item_type] += 1

	return count_map


func transmute():
	if !can_transmute():
		return

	var current_recipe: Dictionary = _get_current_recipe()

	if current_recipe == _2_oils:
		_remove_all_items()

		var item_id: int = _get_random_oil()
		var item: Item = Item.make(item_id)
		add_item(item)


func _get_random_oil() -> int:
	var rarity: Rarity.enm = Rarity.enm.COMMON
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var oil_type_string: String = ItemType.convert_to_string(ItemType.enm.OIL)
	var oil_item_list: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.TYPE, oil_type_string)
	var random_oil: int = oil_item_list.pick_random()

	return random_oil


func _remove_all_items():
	for item in _item_list:
		item.queue_free()

	_item_list.clear()
	items_changed.emit()
