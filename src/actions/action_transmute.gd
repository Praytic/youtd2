class_name ActionTransmute


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSMUTE,
		})

	return action


static func execute(_action: Dictionary, player: Player):
	var horadric_stash: ItemContainer = player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	var current_recipe: HoradricCube.Recipe = HoradricCube.get_current_recipe(player, item_list)
	var can_transmute: bool = current_recipe != HoradricCube.Recipe.NONE
	
	if !can_transmute:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_VALID_RECIPE"))

		return

	var result_item_id_list: Array[int] = HoradricCube.get_result_item_for_recipe(player, current_recipe, item_list)
	var generated_items: bool = !result_item_id_list.is_empty()

	if !generated_items:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_TRANSMUTE_FAILED"))
		
		return

	var result_list: Array[Item] = Utils.item_id_list_to_item_list(result_item_id_list, player)

	for item in item_list:
		horadric_stash.remove_item(item)
	
	for item in result_list:
		horadric_stash.add_item(item)
