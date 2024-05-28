class_name HoradricCube


# NOTE: implements transmutation of items. The UI for
# horadric cube is located in ItemStashMenu scene. Items are
# stored inside ItemContainer which is child of GameScene.
# 
# Tests for some horadric functions can be found in
# TestHoradricTool.gd


# NOTE: these values must match the id's in
# recipe_properties.csv
enum Recipe {
	NONE = 0,
	REBREW = 1,
	DISTILL = 2,
	REASSEMBLE = 3,
	PERFECT = 4,
	LIQUEFY = 5,
	PRECIPITATE = 6,
	IMBUE = 7,
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


#########################
###       Public      ###
#########################

static func has_recipe_ingredients(recipe: Recipe, item_list: Array[Item]) -> bool:
	return !get_item_list_for_autofill(recipe, item_list).is_empty()


static func can_transmute(player: Player, item_list: Array[Item]) -> bool:
	var current_recipe: Recipe = HoradricCube.get_current_recipe(player, item_list)
	var recipe_is_valid: bool = current_recipe != Recipe.NONE

	return recipe_is_valid


# Returns list of filtered items from the provided item_list,
# which can be used for a recipe. Prioritizes items with
# lowest rarity and level. Returns empty list if autofill
# can't be performed.
static func get_item_list_for_autofill(recipe: Recipe, item_list: Array[Item]) -> Array[Item]:
	var current_rarity: Rarity.enm = Rarity.enm.COMMON

	while current_rarity <= Rarity.enm.UNIQUE:
		var result_list: Array[Item] = HoradricCube.get_item_list_for_autofill_for_rarity(recipe, item_list, current_rarity)

		if !result_list.is_empty():
			return result_list
		
		current_rarity = (current_rarity + 1) as Rarity.enm

	return []


static func get_item_list_for_autofill_for_rarity(recipe: Recipe, item_list: Array[Item], rarity: Rarity.enm) -> Array[Item]:
	var rarity_change_from_recipe: int = RecipeProperties.get_rarity_change(recipe)
	var result_rarity: int = rarity + rarity_change_from_recipe
	var result_rarity_is_valid: bool = Rarity.enm.COMMON <= result_rarity && result_rarity <= Rarity.enm.UNIQUE

	if !result_rarity_is_valid:
		return []

# 	Filter rarities
	item_list = item_list.filter(
		func(item: Item) -> bool:
			var item_rarity: Rarity.enm = item.get_rarity()
			var rarity_match: bool = item_rarity == rarity

			return rarity_match
	)

# 	Filter out locked items
	item_list = item_list.filter(
		func(item: Item) -> bool:
			var item_is_locked: bool = item.get_horadric_lock_is_enabled()
			var item_can_be_autofilled: bool = !item_is_locked

			return item_can_be_autofilled
	)

# 	Sort by level to prioritize lower level items first
	item_list.sort_custom(func(a, b): return a.get_required_wave_level() < b.get_required_wave_level())

	var result_list: Array[Item] = []

	var permanent_count: int = RecipeProperties.get_permanent_count(recipe)
	var usable_count: int = RecipeProperties.get_usable_count(recipe)
	var ingredient_list: Array = [
		[[ItemType.enm.REGULAR], permanent_count],
		[[ItemType.enm.OIL, ItemType.enm.CONSUMABLE], usable_count],
	]

	for ingredient in ingredient_list:
		var item_type_list: Array = ingredient[0]
		var required_count: int = ingredient[1]

		var sub_list: Array[Item] = item_list.filter(
			func(item: Item) -> bool:
				var item_type: ItemType.enm = item.get_item_type()
				var item_type_match: bool = item_type_list.has(item_type)

				return item_type_match
		)

		var item_count_is_enough: bool = sub_list.size() >= required_count

		if item_count_is_enough:
			sub_list.resize(required_count)
			result_list.append_array(sub_list)
		else:
			return []

	return result_list


# Returns recipe which matches the given item list. Do this
# by getting an autofill list and checking if autofill list
# is equal to input list.
static func get_current_recipe(player: Player, item_list: Array[Item]) -> Recipe:
	if item_list.is_empty():
		return Recipe.NONE

	var item_id_list: Array[int] = Utils.item_list_to_item_id_list(item_list)

	var recipe_list: Array = RecipeProperties.get_id_list()

	var builder: Builder = player.get_builder()
	var builder_id: int = builder.get_id()
	var backpacked_builder_is_selected: bool = builder_id == BuilderProperties.BACKPACKER_BUILDER_ID

	for recipe in recipe_list:
		var recipe_unlocked_by_backpacker: bool = RecipeProperties.get_unlocked_by_backpacker(recipe)
		var recipe_is_locked: bool = recipe_unlocked_by_backpacker && !backpacked_builder_is_selected

		if recipe_is_locked:
			continue

		var autofill_item_list: Array[Item] = HoradricCube.get_item_list_for_autofill(recipe, item_list)
		var autofill_id_list: Array[int] = Utils.item_list_to_item_id_list(autofill_item_list)

		var recipe_matches: bool = item_id_list == autofill_id_list

		if recipe_matches:
			return recipe
	
	return Recipe.NONE


static func get_result_item_for_recipe(player: Player, recipe: Recipe, item_list: Array[Item]) -> Array[int]:
	var rarity_change_from_recipe: int = RecipeProperties.get_rarity_change(recipe)
	var ingredient_rarity: Rarity.enm = HoradricCube._get_ingredient_rarity(item_list)
	var result_rarity: Rarity.enm = (ingredient_rarity + rarity_change_from_recipe) as Rarity.enm
	var result_item_type: Array[ItemType.enm] = RecipeProperties.get_result_item_type(recipe)
	var avg_ingredient_level: int = HoradricCube._get_average_ingredient_level(item_list)
	var random_bonus_mod: int = HoradricCube._get_random_bonus_mod()
	var lvl_min: int = avg_ingredient_level + RecipeProperties.get_lvl_bonus_min(recipe) + random_bonus_mod	
	var lvl_max: int = avg_ingredient_level + RecipeProperties.get_lvl_bonus_max(recipe) + random_bonus_mod

#	NOTE: for PRECIPITATE recipe need to pick completely
#	random level
	if recipe == Recipe.PRECIPITATE:
		lvl_min = 0
		lvl_max = 100000

	var recipe_is_oil_or_consumable: bool = result_item_type.has(ItemType.enm.OIL) && result_item_type.has(ItemType.enm.CONSUMABLE)
	var recipe_is_regular: bool = result_item_type.has(ItemType.enm.REGULAR)

	var result_item_list: Array[int] = []
	
	var result_count: int = RecipeProperties.get_result_count(recipe)

	for i in range(0, result_count):
		if recipe_is_oil_or_consumable:
			var result_item: int = HoradricCube._get_transmuted_oil_or_consumable(item_list, result_rarity)
			result_item_list.append(result_item)
		elif recipe_is_regular:
			var result_item: int = HoradricCube._get_transmuted_item(item_list, result_rarity, lvl_min, lvl_max)
			result_item_list.append(result_item)

	var luck_message: String
	match random_bonus_mod:
		LEVEL_MOD_UNLUCKY: luck_message = "Transmute was [color=RED]unlucky[/color]: [color=GOLD]%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_NORMAL: luck_message = ""
		LEVEL_MOD_LUCKY: luck_message =  "Transmute was [color=GREEN]lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod
		LEVEL_MOD_SUPER_LUCKY: luck_message =  "Transmute was [color=GOLD]super lucky[/color]: [color=GOLD]+%d[/color] levels!" % random_bonus_mod

	if !luck_message.is_empty():
		Messages.add_normal(player, luck_message)

	return result_item_list


#########################
###      Private      ###
#########################

static func _get_transmuted_oil_or_consumable(item_list: Array[Item], rarity: Rarity.enm) -> int:
	var oil_list: Array = ItemDropCalc.get_oil_and_consumables_list(rarity)

# 	Remove ingredients from item pool so that trasmute result is different from ingredients
	var ingredient_list: Array[int] = Utils.item_list_to_item_id_list(item_list)
	for ingredient in ingredient_list:
		oil_list.erase(ingredient)

	if oil_list.is_empty():
		push_error("Possible result pool for transmuting oils is empty. This shouldn't happen.")

		return 0

	var random_oil: int = Utils.pick_random(Globals.synced_rng, oil_list)

	return random_oil


static func _get_transmuted_item(ingredient_item_list: Array[Item], rarity: Rarity.enm, lvl_min: int, lvl_max: int) -> int:
	var current_lvl_min: int = lvl_min
	var item_list: Array[int] = []
	var loop_count: int = 0

#	It's possible for random item pool to be empty if
#	level of ingredients is too high, in this case,
#	lower the lower lvl bound to make the pool not empty
	while item_list.is_empty():
		item_list = ItemDropCalc.get_item_list_bounded(rarity, current_lvl_min, lvl_max)

# 		Remove ingredients from item pool so that transmute result is different from ingredients
		var ingredient_list: Array[int] = Utils.item_list_to_item_id_list(ingredient_item_list)
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

	var random_item: int = Utils.pick_random(Globals.synced_rng, item_list)
	
	return random_item


static func _get_ingredient_rarity(item_list: Array[Item]) -> Rarity.enm:
	if item_list.is_empty():
		return Rarity.enm.COMMON

	var first_item: Item = item_list[0]
	var rarity: Rarity.enm = first_item.get_rarity()

	return rarity


static func _get_average_ingredient_level(item_list: Array[Item]) -> int:
	if item_list.is_empty():
		return 0

	var sum: float = 0.0

	for item in item_list:
#		NOTE: only check level of permanent items. Skip oils
#		and consumables. Important for Imbue recipe.
		var item_is_permanent: bool = ItemProperties.get_type(item.get_id()) == ItemType.enm.REGULAR

		if !item_is_permanent:
			continue

		var item_id: int = item.get_id()
		var level: int = ItemProperties.get_required_wave_level(item_id)
		sum += level

	var item_count: int = item_list.size()
	var average_level: int = floori(sum / item_count)

	return average_level


static func _get_random_bonus_mod() -> int:
	var bonus_mod: int = Utils.random_weighted_pick(Globals.synced_rng, _bonus_mod_chance_map)

	return bonus_mod
