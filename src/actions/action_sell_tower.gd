class_name ActionSellTower


static func make(tower_unit_id_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELL_TOWER,
		Action.Field.UID: tower_unit_id_arg,
		})

	return action


static func verify(player: Player, tower: Tower) -> bool:
	if tower == null:
		Utils.add_ui_error(player, "Failed to sell tower")

		return false

	var player_match: bool = tower.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, "You don't own this tower")

		return false

	return true


static func execute(action: Dictionary, player: Player, build_space: BuildSpace):
	var tower_uid: int = action[Action.Field.UID]

	var tower_node: Node = GroupManager.get_by_uid("towers", tower_uid)
	var tower: Tower = tower_node as Tower

	var verify_ok: bool = ActionSellTower.verify(player, tower)
	if !verify_ok:
		return

# 	Return tower items to item stash
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var tower_id: int = tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	player.give_gold(sell_price, tower, true, true)
	player.remove_food_for_tower(tower_id)

	build_space.set_occupied_by_tower(tower, false)

	tower.remove_from_game()
