class_name TestHoradricTool extends Node


# Enable by adding "config/run_test_horadric_tool=true" to
# override.cfg


static func run():
	test_get_item_list_for_autofill()
	test_get_result_item_for_recipe()
	TestTool.print_totals()


class TestCase_get_item_list_for_autofill extends TestTool.TestCase_base:
	var recipe: HoradricCube.Recipe
	var ingredient_list: Array[int] = []
	var expected_result_list: Array[int] = []

	func _init(recipe_arg: HoradricCube.Recipe, ingredient_list_arg: Array[int], expected_result_list_arg: Array[int], description_arg: String):
		recipe = recipe_arg
		ingredient_list = ingredient_list_arg
		expected_result_list = expected_result_list_arg
		description = description_arg


static func test_get_item_list_for_autofill():
	var test_case_list: Array[TestCase_get_item_list_for_autofill] = [
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [1001, 1001], [1001, 1001], "2 oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [1005, 1005, 1001, 1011, 1001, 1, 2, 3], [1001, 1001], "2 oils mixed with items and other oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.NONE, [1, 1001], [], "1 oil and 1 item."),
		
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [1003, 1006, 1009, 1015], [1003, 1006, 1009, 1015], "4 oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [1003, 1006, 2004, 2004], [1003, 1006, 2004, 2004], "2 oils and 2 consumables. Mixing should be allowed."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5], [3, 4, 5], "3 items."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5, 6, 7], [5, 6, 7], "5 items. Lowest level should be picked."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5, 36, 37, 38], [36, 37, 38], "3 uncommon items and 3 common items. Lowest rarity should be picked."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67, 68], [64, 65, 66, 67, 68], "5 items."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [1001, 1002, 1003, 10, 64, 65, 66, 198, 67, 68], [64, 65, 66, 67, 68], "5 items mixed with other items and oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67], [], "4 items. Not enough for Perfect"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67, 74], [], "5 items but item74 is different rarity."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [], [], "0 items for reassemble"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [], [], "0 items for perfect"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [], [], "0 items for distill"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [], [], "0 items for rebrew"),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [2008, 2008, 2008, 2008, 2008], [], "4 unique oils for DISTILL. Invalid because can't raise rarity further."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [1, 1, 1, 1, 1], [], "5 permanent items for PERFECT. Invalid because can't raise rarity further."),
	]

	var test_case_function: Callable = func(test_case: TestCase_get_item_list_for_autofill):
		var recipe: HoradricCube.Recipe = test_case.recipe
		var ingredient_list: Array[int] = test_case.ingredient_list
		var ingredient_item_list: Array[Item] = Utils.item_id_list_to_item_list(ingredient_list)
		var expected_result_list: Array[int] = test_case.expected_result_list
		var actual_result_item_list: Array[Item] = HoradricCube._get_item_list_for_autofill(recipe, ingredient_item_list)
		var actual_result_list: Array[int] = Utils.item_list_to_item_id_list(actual_result_item_list)

		TestTool.compare(actual_result_list, expected_result_list, "result list")

	TestTool.run("get_item_list_for_autofill()", test_case_list, test_case_function)


class TestCase_get_result_item_for_recipe extends TestTool.TestCase_base:
	var recipe: HoradricCube.Recipe
	var ingredient_list: Array[int] = []
	var expected_result_rarity: Rarity.enm
	var expected_result_item_type: Array[ItemType.enm] = []
	var expected_result_count: int

	func _init(recipe_arg: HoradricCube.Recipe, ingredient_list_arg: Array[int], expected_result_rarity_arg: Rarity.enm, expected_result_item_type_arg: Array[ItemType.enm], expected_result_count_arg: int, description_arg: String):
		recipe = recipe_arg
		ingredient_list = ingredient_list_arg
		expected_result_rarity = expected_result_rarity_arg
		expected_result_item_type = expected_result_item_type_arg
		expected_result_count = expected_result_count_arg
		description = description_arg


static func test_get_result_item_for_recipe():
	var test_case_list: Array[TestCase_get_result_item_for_recipe] = [
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.REBREW, [1001, 1001], Rarity.enm.COMMON, [ItemType.enm.OIL, ItemType.enm.CONSUMABLE], 1, "rebrew 2 common oils"),
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.DISTILL, [1001, 1001, 1001, 1001], Rarity.enm.UNCOMMON, [ItemType.enm.OIL, ItemType.enm.CONSUMABLE], 1, "rebrew 4 common oils into uncommon oil"),
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.REASSEMBLE, [64, 64, 64], Rarity.enm.COMMON, [ItemType.enm.REGULAR], 1, "reassemble 3 common permanent items"),
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.PERFECT, [64, 64, 64, 64, 64], Rarity.enm.UNCOMMON, [ItemType.enm.REGULAR], 1, "perfect 5 common permanent items into uncommon item"),

		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.LIQUEFY, [8, 8], Rarity.enm.COMMON, [ItemType.enm.OIL, ItemType.enm.CONSUMABLE], 3, "LIQUEFY 2 rare items into 3 common oils"),
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.LIQUEFY, [1, 1], Rarity.enm.UNCOMMON, [ItemType.enm.OIL, ItemType.enm.CONSUMABLE], 3, "LIQUEFY 2 unique items into 3 uncommon oils"),

		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.PRECIPITATE, [1001, 1001], Rarity.enm.RARE, [ItemType.enm.REGULAR], 1, "PRECIPITATE 6 common oils into 1 rare item"),
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.PRECIPITATE, [1002, 1002], Rarity.enm.UNIQUE, [ItemType.enm.REGULAR], 1, "PRECIPITATE 6 uncommon oils into 1 rare item"),
		
		TestCase_get_result_item_for_recipe.new(HoradricCube.Recipe.IMBUE, [2, 1001, 1001, 1001, 1001], Rarity.enm.UNCOMMON, [ItemType.enm.REGULAR], 1, "IMBUE 1 common item and 4 common oils into 1 uncommon item"),

	]

	var test_case_function: Callable = func(test_case: TestCase_get_result_item_for_recipe):
		var recipe: HoradricCube.Recipe = test_case.recipe
		var ingredient_id_list: Array[int] = test_case.ingredient_list
		var ingredient_item_list: Array[Item] = Utils.item_id_list_to_item_list(ingredient_id_list)
		var result_item_list: Array[int] = HoradricCube._get_result_item_for_recipe(recipe, ingredient_item_list)

		var expected_result_count: int = test_case.expected_result_count
		var actual_result_count: int = result_item_list.size()
		TestTool.compare(actual_result_count, expected_result_count, "result count")

		var expected_result_rarity: Rarity.enm = test_case.expected_result_rarity
		for result_item in result_item_list:
			var actual_result_rarity: Rarity.enm = ItemProperties.get_rarity(result_item)
			TestTool.compare(actual_result_rarity, expected_result_rarity, "result rarity")

		var expected_result_item_type: Array[ItemType.enm] = test_case.expected_result_item_type
		for result_item in result_item_list:
			var actual_result_item_type: ItemType.enm = ItemProperties.get_type(result_item)
			TestTool.verify(expected_result_item_type.has(actual_result_item_type))

	TestTool.run("get_result_item_for_recipe()", test_case_list, test_case_function)
