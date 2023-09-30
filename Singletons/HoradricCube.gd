extends Node


signal items_changed()


enum Recipe {
	TWO_OILS_OR_CONSUMABLES,
	FOUR_OILS_OR_CONSUMABLES,
	THREE_ITEMS,
	FIVE_ITEMS,
	NONE,
}

var _level_bonus_map: Dictionary = {
	Recipe.TWO_OILS_OR_CONSUMABLES: [0, 0],
	Recipe.FOUR_OILS_OR_CONSUMABLES: [0, 0],
	Recipe.THREE_ITEMS: [5, 25],
	Recipe.FIVE_ITEMS: [0, 20],
	Recipe.NONE: [0, 0],
}


const CAPACITY: int = 5
const LEVEL_MOD_UNLUCKY: int = -9
const LEVEL_MOD_NORMAL: int = 0
const LEVEL_MOD_LUCKY: int = 7
const LEVEL_MOD_SUPER_LUCKY: int = 18

const _bonus_mod_chance_map: Dictionary = {
	LEVEL_MOD_UNLUCKY: 20,
	LEVEL_MOD_NORMAL: 50,
	LEVEL_MOD_LUCKY: 20,
	LEVEL_MOD_SUPER_LUCKY: 10
}

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


# Creates new item based on the recipe and adds it to the item container.
# Returns the message with transmutation details to the caller.
func transmute() -> String:
	var current_recipe: Recipe = _get_current_recipe()
	
	if current_recipe == Recipe.NONE:
		return "Change the ingredients to match an existing recipe."

	var failed_because_max_rarity: bool = _cant_increase_rarity_further(current_recipe)
	if failed_because_max_rarity:
		Messages.add_error("Can't transmute, ingredients are already at max rarity.")

		return "Can't transmute, ingredients are already at max rarity."

	var result = _get_result_item_for_recipe(current_recipe)

	if result.item_id == 0:
		push_error("Transmute failed to generate any items, this shouldn't happen.")

		return "Something went wrong..."

	_remove_all_items()

	var result_item: Item = Item.make(result.item_id)
	_item_container.add_item(result_item)
	
	return result.message


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
	var all_oils_or_consumables: bool = !item_type_list.has(ItemType.enm.REGULAR)
	var same_rarity: bool = rarity_list.size() == 1
	var item_count: int = item_list.size()

	if !same_rarity:
		return Recipe.NONE
	elif all_oils_or_consumables:
		if item_count == 2:
			return Recipe.TWO_OILS_OR_CONSUMABLES
		elif item_count == 4:
			return Recipe.FOUR_OILS_OR_CONSUMABLES
	elif all_items:
		if item_count == 3:
			return Recipe.THREE_ITEMS
		elif item_count == 5:
			return Recipe.FIVE_ITEMS

	return Recipe.NONE


func _get_result_item_for_recipe(recipe: Recipe):
	var ingredient_list: Array[int] = _get_ingredient_id_list()
	var result_rarity: Rarity.enm = _get_result_rarity(recipe)
	var result_item_type: ItemType.enm = _get_result_item_type(recipe)
	var avg_ingredient_level: int = _get_average_ingredient_level()
	var random_bonus_mod: int = _get_random_bonus_mod()
	var lvl_min: int = avg_ingredient_level + _level_bonus_map[recipe][0] + random_bonus_mod	
	var lvl_max: int = avg_ingredient_level + _level_bonus_map[recipe][1] + random_bonus_mod	

# 	Generate a result item which is not equal to any of the
# 	ingredients
	var result_item: int
	var attempt_count: int = 0
	while true:
		result_item = _get_result_item_base(result_item_type, result_rarity, lvl_min, lvl_max)
		attempt_count += 1

		var result_is_different_from_ingredients: bool = !ingredient_list.has(result_item)
		if result_is_different_from_ingredients:
			break

		if attempt_count > 100:
			push_error("Failed to generate unique transmute result after 100 tries. Shouldn't happen.")
			break

	var luck_message: String
	match random_bonus_mod:
		LEVEL_MOD_UNLUCKY: luck_message = "Transmute was [color=RED]unlucky[/color]: [color=GOLD]%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_NORMAL: luck_message = ""
		LEVEL_MOD_LUCKY: luck_message =  "Transmute was [color=GREEN]lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_SUPER_LUCKY: luck_message =  "Transmute was [color=GOLD]super lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod

	if !luck_message.is_empty():
		Messages.add_normal(luck_message)

	return {"item_id": result_item, "message": luck_message}


func _get_result_item_base(item_type: ItemType.enm, rarity: Rarity.enm, lvl_min: int, lvl_max: int) -> int:
	match item_type:
		ItemType.enm.OIL: return ItemDropCalc.get_random_oil_or_consumable(rarity)
		ItemType.enm.REGULAR: return ItemDropCalc.get_random_item_at_or_below_rarity_bounded(rarity, lvl_min, lvl_max)
		_:
			push_error("Invalid recipe")
	
	return 0


func _cant_increase_rarity_further(recipe: Recipe) -> bool:
	var ingredient_rarity: Rarity.enm = _get_ingredient_rarity()
	var can_increase_rarity: bool = ingredient_rarity != Rarity.enm.UNIQUE
	var recipe_increases_rarity: bool = recipe == Recipe.FOUR_OILS_OR_CONSUMABLES || recipe == Recipe.FIVE_ITEMS
	var recipe_fails: bool = recipe_increases_rarity && !can_increase_rarity

	return recipe_fails


func _get_result_rarity(recipe: Recipe) -> Rarity.enm:
	var ingredient_rarity: Rarity.enm = _get_ingredient_rarity()
	var next_rarity: Rarity.enm = _get_next_rarity(ingredient_rarity)

	match recipe:
		Recipe.TWO_OILS_OR_CONSUMABLES: return ingredient_rarity
		Recipe.FOUR_OILS_OR_CONSUMABLES: return next_rarity
		Recipe.THREE_ITEMS: return ingredient_rarity
		Recipe.FIVE_ITEMS: return next_rarity
		_: return Rarity.enm.COMMON


func _get_result_item_type(recipe: Recipe) -> ItemType.enm:
	match recipe:
		Recipe.TWO_OILS_OR_CONSUMABLES: return ItemType.enm.OIL
		Recipe.FOUR_OILS_OR_CONSUMABLES: return ItemType.enm.OIL
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


func _get_average_ingredient_level() -> int:
	var item_list: Array[Item] = _item_container.get_item_list()

	if item_list.is_empty():
		return 0

	var sum: float = 0.0

	for item in item_list:
		var item_id: int = item.get_id()
		var level: int = ItemProperties.get_required_wave_level(item_id)
		sum += level

	var item_count: int = item_list.size()
	var average_level: int = floori(sum / item_count)

	return average_level


func _get_random_bonus_mod() -> int:
	var bonus_mod: int = Utils.random_weighted_pick(_bonus_mod_chance_map)

	return bonus_mod


func _get_ingredient_id_list() -> Array[int]:
	var id_list: Array[int] = []
	var item_list: Array[Item] = _item_container.get_item_list()
	
	for item in item_list:
		var id: int = item.get_id()
		id_list.append(id)

	return id_list
