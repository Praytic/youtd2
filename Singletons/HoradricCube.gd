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

var _recipe_item_count_map: Dictionary = {
	Recipe.TWO_OILS_OR_CONSUMABLES: 2, 
	Recipe.FOUR_OILS_OR_CONSUMABLES: 4, 
	Recipe.THREE_ITEMS: 3, 
	Recipe.FIVE_ITEMS: 5, 
	Recipe.NONE: 0, 
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


#########################
###     Built-in      ###
#########################

func _ready():
	_item_container = ItemContainer.new(CAPACITY)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)


#########################
###       Public      ###
#########################

func get_item_container() -> ItemContainer:
	return _item_container


func has_recipe_ingredients(recipe: Recipe, item_list: Array[Item]) -> bool:
	return !_get_item_list_for_autofill(recipe, item_list).is_empty()


func can_transmute() -> bool:
	var item_list: Array[Item] = _item_container.get_item_list()
	var current_recipe: Recipe = _get_current_recipe(item_list)
	var recipe_is_valid: bool = current_recipe != Recipe.NONE

	return recipe_is_valid


# Creates new item based on the recipe and adds it to the item container.
# Returns the message with transmutation details to the caller.
func transmute() -> String:
	var item_list: Array[Item] = _item_container.get_item_list()
	var current_recipe: Recipe = _get_current_recipe(item_list)
	
	if current_recipe == Recipe.NONE:
		return "Change the ingredients to match an existing recipe."

#	NOTE: autofill will not move unique items into cube if
#	recipe raises rarity BUT player can still manually setup
#	a situation like this. That's why we need a secondary
#	check here.
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


func autofill_recipe(recipe: Recipe, rarity_filter: Array = []) -> bool:
	var item_stash_container: ItemContainer = ItemStash.get_item_container()

# 	Return current cube contents to item stash
	var current_contents: Array[Item] = _item_container.get_item_list()
	for item in current_contents:
		_item_container.remove_item(item)
		item_stash_container.add_item(item)

#	Move items from item stash to cube, if there are enough
#	items for the recipe
	var item_list: Array[Item] = item_stash_container.get_item_list(rarity_filter)
	var autofill_list: Array[Item] = _get_item_list_for_autofill(recipe, item_list)
	var can_autofill: bool = !autofill_list.is_empty()

	if can_autofill:
		for item in autofill_list:
			item_stash_container.remove_item(item)
			_item_container.add_item(item)

		return true
	else:
		Messages.add_error("Not enough items for recipe!")

		return false


#########################
###      Private      ###
#########################

# Returns list of filtered items from the provided item_list,
# which can be used for a recipe. Prioritizes items with
# lowest rarity and level. Returns empty list if autofill
# can't be performed.
func _get_item_list_for_autofill(recipe: Recipe, item_list: Array[Item]) -> Array[Item]:
	var recipe_item_type: Array[ItemType.enm] = _get_result_item_type_list(recipe)
	var recipe_item_count: int = _recipe_item_count_map[recipe]

# 	Filter out items we can't use
	item_list = item_list.filter(
		func(item: Item) -> bool:
			var item_type: ItemType.enm = item.get_item_type()
			var item_type_match: bool = recipe_item_type.has(item_type)

			return item_type_match
	)

# 	Filter out unique items if recipe raises rarity
	var raise_rarity_recipe_list: Array = [Recipe.FOUR_OILS_OR_CONSUMABLES, Recipe.FIVE_ITEMS]
	var recipe_raises_rarity: bool = raise_rarity_recipe_list.has(recipe)
	if recipe_raises_rarity:
		item_list = item_list.filter(
			func(item: Item) -> bool:
				var item_rarity: Rarity.enm = item.get_rarity()
				var rarity_ok: bool = item_rarity != Rarity.enm.UNIQUE

				return rarity_ok
		)

# 	Sort by rarity and level
	var rarity_map: Dictionary = {}
	var rarity_list: Array[Rarity.enm] = Rarity.get_list()
	for rarity in rarity_list:
		var items_of_rarity: Array = item_list.filter(
			func(item: Item) -> bool:
				var item_rarity: Rarity.enm = item.get_rarity()
				var rarity_match: bool = item_rarity == rarity

				return rarity_match
		)

		items_of_rarity.sort_custom(func(a, b): return a.get_required_wave_level() < b.get_required_wave_level())

		rarity_map[rarity] = items_of_rarity

	for rarity in rarity_list:
		var items_of_rarity: Array = rarity_map[rarity]
		var item_count_is_enough: bool = items_of_rarity.size() >= recipe_item_count

		if item_count_is_enough:
			items_of_rarity.resize(recipe_item_count)

			return items_of_rarity

	var invalid_item_list: Array[Item] = []

	return invalid_item_list


func _get_current_recipe(item_list: Array[Item]) -> Recipe:
	var item_type_map: Dictionary = {}
	var rarity_map: Dictionary = {}
	
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
	var result_rarity: Rarity.enm = _get_result_rarity(recipe)
	var result_item_type: Array[ItemType.enm] = _get_result_item_type_list(recipe)
	var avg_ingredient_level: int = _get_average_ingredient_level()
	var random_bonus_mod: int = _get_random_bonus_mod()
	var lvl_min: int = avg_ingredient_level + _level_bonus_map[recipe][0] + random_bonus_mod	
	var lvl_max: int = avg_ingredient_level + _level_bonus_map[recipe][1] + random_bonus_mod	

	var result_item: int
	var recipe_is_oil_or_consumable: bool = result_item_type.has(ItemType.enm.OIL) && result_item_type.has(ItemType.enm.CONSUMABLE)
	var recipe_is_regular: bool = result_item_type.has(ItemType.enm.REGULAR)
	if recipe_is_oil_or_consumable:
		result_item = _get_transmuted_oil_or_consumable(result_rarity)
	elif recipe_is_regular:
		result_item = _get_transmuted_item(result_rarity, lvl_min, lvl_max)
	else:
		result_item = 0
		push_error("Invalid recipe")

	var luck_message: String
	match random_bonus_mod:
		LEVEL_MOD_UNLUCKY: luck_message = "Transmute was [color=RED]unlucky[/color]: [color=GOLD]%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_NORMAL: luck_message = ""
		LEVEL_MOD_LUCKY: luck_message =  "Transmute was [color=GREEN]lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_SUPER_LUCKY: luck_message =  "Transmute was [color=GOLD]super lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod

	if !luck_message.is_empty():
		Messages.add_normal(luck_message)

	return {"item_id": result_item, "message": luck_message}


func _get_transmuted_oil_or_consumable(rarity: Rarity.enm) -> int:
	var oil_list: Array = ItemDropCalc.get_oil_and_consumables_list(rarity)

# 	Remove ingredients from item pool so that trasmute result is different from ingredients
	var ingredient_list: Array[int] = _get_ingredient_id_list()
	for ingredient in ingredient_list:
		oil_list.erase(ingredient)

	if oil_list.is_empty():
		push_error("Possible result pool for transmuting oils is empty. This shouldn't happen.")

		return 0

	var random_oil: int = oil_list.pick_random()

	return random_oil


func _get_transmuted_item(rarity: Rarity.enm, lvl_min: int, lvl_max: int) -> int:
	var current_lvl_min: int = lvl_min
	var item_list: Array[int] = []
	var loop_count: int = 0

#	It's possible for random item pool to be empty if
#	level of ingredients is too high, in this case,
#	lower the lower lvl bound to make the pool not empty
	while item_list.is_empty():
		item_list = ItemDropCalc.get_item_list_bounded(rarity, current_lvl_min, lvl_max)

# 		Remove ingredients from item pool so that transmute result is different from ingredients
		var ingredient_list: Array[int] = _get_ingredient_id_list()
		for ingredient in ingredient_list:
			item_list.erase(ingredient)

		current_lvl_min -= 10

		loop_count += 1

		if loop_count > 10:
			item_list = []

			break

	if item_list.is_empty():
		push_error("Possible result pool for transmuting items is empty. This shouldn't happen.")

		return 0

	var random_item: int = item_list.pick_random()
	
	return random_item


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


func _get_result_item_type_list(recipe: Recipe) -> Array[ItemType.enm]:
	match recipe:
		Recipe.TWO_OILS_OR_CONSUMABLES: return [ItemType.enm.OIL, ItemType.enm.CONSUMABLE]
		Recipe.FOUR_OILS_OR_CONSUMABLES: return [ItemType.enm.OIL, ItemType.enm.CONSUMABLE]
		Recipe.THREE_ITEMS: return [ItemType.enm.REGULAR]
		Recipe.FIVE_ITEMS: return [ItemType.enm.REGULAR]
		_: return [ItemType.enm.REGULAR]


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


#########################
###     Callbacks     ###
#########################

func _on_item_container_items_changed():
	items_changed.emit()

