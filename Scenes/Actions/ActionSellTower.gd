class_name ActionSellTower


static func make(tower_unit_id_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELL_TOWER,
		Action.Field.UID: tower_unit_id_arg,
		})

	return action


static func execute(action: Dictionary, player: Player, map: Map):
	var tower_uid: int = action[Action.Field.UID]

	var tower_node: Node = GroupManager.get_by_uid("towers", tower_uid)
	var tower: Tower = tower_node as Tower

	if tower == null:
		push_error("Sell tower action failed")

		return

# 	Return tower items to item stash
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var tower_id: int = tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	player.give_gold(sell_price, tower, false, true)
	player.remove_food_for_tower(tower_id)

	map.clear_space_occupied_by_tower(tower)

	tower.remove_from_game()
