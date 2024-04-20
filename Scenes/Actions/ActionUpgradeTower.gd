class_name ActionUpgradeTower


static func make(tower_uid: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.UPGRADE_TOWER,
		Action.Field.UID: tower_uid
		})

	return action


static func verify(preceding_tower: Tower) -> bool:
	var preceding_tower_id: int = preceding_tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(preceding_tower_id)

	if upgrade_id == -1:
		print_debug("Failed to find upgrade id")

		return false

	var player: Player = preceding_tower.get_player()

	var enough_gold: bool = player.enough_gold_for_tower(upgrade_id)
	if !enough_gold:
		Messages.add_error(player, "Not enough gold.")

		return false

	return true


static func execute(action: Dictionary, player: Player, select_unit: SelectUnit):
	var preceding_tower_uid: int = action[Action.Field.UID]
	var preceding_tower_node: Node = GroupManager.get_by_uid("towers", preceding_tower_uid)
	var preceding_tower: Tower = preceding_tower_node as Tower

	if preceding_tower == null:
		push_error("Failed to find preceding_tower")

		return
	
	var verify_ok: bool = ActionUpgradeTower.verify(preceding_tower)

	if !verify_ok:
		return

	var preceding_tower_id: int = preceding_tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(preceding_tower_id)
	var upgrade_tower: Tower = Tower.make(upgrade_id, player, preceding_tower)
	var preceding_tower_pos: Vector2 = preceding_tower.get_position_wc3_2d()
	upgrade_tower.set_position_wc3_2d(preceding_tower_pos)
	Utils.add_object_to_world(upgrade_tower)
	preceding_tower.remove_from_game()

	if player == PlayerManager.get_local_player():
		select_unit.set_selected_unit(upgrade_tower)

	var refund_for_prev_tier: float = TowerProperties.get_cost(preceding_tower_id)
	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	player.add_gold(refund_for_prev_tier)
	player.spend_gold(upgrade_cost)
