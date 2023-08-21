extends Node


signal items_changed()


enum Recipe {
	TWO_OILS,
	FOUR_OILS,
	THREE_ITEMS,
	FIVE_ITEMS,
	NONE,
}


const CAPACITY: int = 5


var _item_container: ItemContainer


func _ready():
	_item_container = ItemContainer.new(CAPACITY)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)


func get_item_container() -> ItemContainer:
	return _item_container


func can_transmute() -> bool:
	var current_recipe: Recipe = _get_current_recipe()
	var recipe_is_valid: bool = current_recipe != Recipe.NONE

	return recipe_is_valid


func transmute():
	var current_recipe: Recipe = _get_current_recipe()
	
	if current_recipe == Recipe.NONE:
		return

	var failed_because_max_rarity: bool = _cant_increase_rarity_further(current_recipe)
	if failed_because_max_rarity:
		Messages.add_error("Can't transmute, ingredients are already at max rarity.")

		return

	var result_item_id: int = _get_result_item_for_recipe(current_recipe)

	if result_item_id == 0:
		push_error("Transmute failed to generate any items, this shouldn't happen.")

		return

	_remove_all_items()

	var result_item: Item = Item.make(result_item_id)
	_item_container.add_item(result_item)


func _get_current_recipe() -> Recipe:
	var item_type_map: Dictionary = {}
	var rarity_map: Dictionary = {}
	var item_list: Array[Item] = _item_container.get_item_list()

	for item in item_list:
		var item_id: int = item.get_id()
		var item_type: ItemType.enm = ItemProperties.get_type(item_id)
		var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)

		item_type_map[item_type] = true
		rarity_map[rarity] = true

	var item_type_list: Array = item_type_map.keys()
	var rarity_list: Array = rarity_map.keys()
	var all_items: bool = item_type_list == [ItemType.enm.REGULAR]
	var all_oils: bool = item_type_list == [ItemType.enm.OIL]
	var same_type: bool = item_type_list.size() == 1
	var same_rarity: bool = rarity_list.size() == 1
	var item_count: int = item_list.size()

	if !same_type || !same_rarity:
		return Recipe.NONE

	if all_oils:
		if item_count == 2:
			return Recipe.TWO_OILS
		elif item_count == 4:
			return Recipe.FOUR_OILS
	elif all_items:
		if item_count == 3:
			return Recipe.THREE_ITEMS
		elif item_count == 5:
			return Recipe.FIVE_ITEMS

	return Recipe.NONE


func _get_result_item_for_recipe(recipe: Recipe) -> int:
	var result_rarity: Rarity.enm = _get_result_rarity(recipe)
	var result_item_type: ItemType.enm = _get_result_item_type(recipe)
	var rarity_string: String = Rarity.convert_to_string(result_rarity)
	var item_type_string: String = ItemType.convert_to_string(result_item_type)
	var possible_results: Array = Properties.get_item_id_list_by_filter(Item.CsvProperty.TYPE, item_type_string)
	possible_results = Properties.filter_item_id_list(possible_results, Item.CsvProperty.RARITY, rarity_string)

	if possible_results.is_empty():
		return 0

	var result_item: int = possible_results.pick_random()

	return result_item


func _cant_increase_rarity_further(recipe: Recipe) -> bool:
	var ingredient_rarity: Rarity.enm = _get_ingredient_rarity()
	var can_increase_rarity: bool = ingredient_rarity != Rarity.enm.UNIQUE
	var recipe_increases_rarity: bool = recipe == Recipe.FOUR_OILS || recipe == Recipe.FIVE_ITEMS
	var recipe_fails: bool = recipe_increases_rarity && !can_increase_rarity

	return recipe_fails


func _get_result_rarity(recipe: Recipe) -> Rarity.enm:
	var ingredient_rarity: Rarity.enm = _get_ingredient_rarity()
	var next_rarity: Rarity.enm = _get_next_rarity(ingredient_rarity)

	match recipe:
		Recipe.TWO_OILS: return ingredient_rarity
		Recipe.FOUR_OILS: return next_rarity
		Recipe.THREE_ITEMS: return ingredient_rarity
		Recipe.FIVE_ITEMS: return next_rarity
		_: return Rarity.enm.COMMON


func _get_result_item_type(recipe: Recipe) -> ItemType.enm:
	match recipe:
		Recipe.TWO_OILS: return ItemType.enm.OIL
		Recipe.FOUR_OILS: return ItemType.enm.OIL
		Recipe.THREE_ITEMS: return ItemType.enm.REGULAR
		Recipe.FIVE_ITEMS: return ItemType.enm.REGULAR
		_: return ItemType.enm.OIL


func _get_ingredient_rarity() -> Rarity.enm:
	var item_list: Array[Item] = _item_container.get_item_list()
	
	if item_list.is_empty():
		return Rarity.enm.COMMON

	var first_item: Item = item_list[0]
	var rarity: Rarity.enm = first_item.get_rarity()

	return rarity


func _get_next_rarity(rarity: Rarity.enm) -> Rarity.enm:
	if rarity == Rarity.enm.UNIQUE:
		return rarity
	else:
		var next_rarity: Rarity.enm = (rarity + 1) as Rarity.enm

		return next_rarity


func _remove_all_items():
	var item_list: Array[Item] = _item_container.get_item_list()

	for item in item_list:
		_item_container.remove_item(item)
		item.queue_free()


func _on_item_container_items_changed():
	items_changed.emit()
