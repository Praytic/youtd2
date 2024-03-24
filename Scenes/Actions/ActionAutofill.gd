class_name ActionAutofill


static func make(recipe_arg: HoradricCube.Recipe, rarity_filter_arg: Array) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.AUTOFILL,
		Action.Field.AUTOFILL_RECIPE: recipe_arg,
		Action.Field.AUTOFILL_RARITY_FILTER: rarity_filter_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var recipe: HoradricCube.Recipe = action[Action.Field.AUTOFILL_RECIPE]
	var rarity_filter: Array = action[Action.Field.AUTOFILL_RARITY_FILTER]

	var item_stash: ItemContainer = player.get_item_stash()
	var horadric_stash: ItemContainer = player.get_horadric_stash()

# 	Return current cube contents to item stash. Need to do this first in all cases, doesn't matter if autofill suceeeds or fails later.
	var horadric_items_initial: Array[Item] = horadric_stash.get_item_list()
	for item in horadric_items_initial:
		horadric_stash.remove_item(item)
		item_stash.add_item(item)

#	Move items from item stash to cube, if there are enough
#	items for the recipe
	var full_item_list: Array[Item] = item_stash.get_item_list()
	var filtered_item_list: Array[Item] = Utils.filter_item_list(full_item_list, rarity_filter)
	var autofill_list: Array[Item] = HoradricCube.get_item_list_for_autofill(recipe, filtered_item_list)
	
	var can_autofill: bool = !autofill_list.is_empty()
	
	if !can_autofill:
		Messages.add_error(player, "Not enough items for recipe!")
		
		return

#	Move autofill items from item stash to horadric stash
	for item in autofill_list:
		item_stash.remove_item(item)
		horadric_stash.add_item(item)
