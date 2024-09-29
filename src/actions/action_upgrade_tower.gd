class_name ActionUpgradeTower


static func make(tower_uid: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.UPGRADE_TOWER,
		Action.Field.UID: tower_uid
		})

	return action


static func verify(player: Player, prev_tower: Tower) -> bool:
	if prev_tower == null:
		Utils.add_ui_error(player, "Failed to upgrade")

		return false

	var player_match: bool = prev_tower.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, "You don't own this tower")
		
		return false

	var prev_tower_id: int = prev_tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(prev_tower_id)
	if upgrade_id == -1:
		Utils.add_ui_error(player, "Failed to find upgrade id")

		return false

	var enough_resources: bool = BuildTower.enough_resources_for_tower(upgrade_id, player, prev_tower_id)
	if !enough_resources:
		BuildTower.add_error_about_building_tower(upgrade_id, player, prev_tower_id)

		return false

	var transform_is_allowed: bool = prev_tower.get_transform_is_allowed()
	if !transform_is_allowed:
		Utils.add_ui_error(player, "Can't transform right now")

		return false

	return true


static func execute(action: Dictionary, player: Player, select_unit: SelectUnit):
	var preceding_tower_uid: int = action[Action.Field.UID]
	var preceding_tower_node: Node = GroupManager.get_by_uid("towers", preceding_tower_uid)
	var preceding_tower: Tower = preceding_tower_node as Tower

	var verify_ok: bool = ActionUpgradeTower.verify(player, preceding_tower)
	if !verify_ok:
		return

# 	NOTE: order is important here. Need to set position
# 	before adding to world so that correct position can be
# 	accessed in tower's on_create().
	var preceding_tower_id: int = preceding_tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(preceding_tower_id)
	var upgrade_tower: Tower = Tower.make(upgrade_id, player, preceding_tower)
	var prev_tower_pos: Vector2 = preceding_tower.get_position_wc3_2d()
	upgrade_tower.set_position_wc3_2d(prev_tower_pos)
	Utils.add_object_to_world(upgrade_tower)
	preceding_tower.remove_from_game()

	if player == PlayerManager.get_local_player():
		select_unit.set_selected_unit(upgrade_tower)

	var refund_for_prev_tier: float = TowerProperties.get_cost(preceding_tower_id)
	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	player.add_gold(refund_for_prev_tier)
	player.spend_gold(upgrade_cost)

	var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/upgrade_tower.tscn", upgrade_tower, Unit.BodyPart.ORIGIN)
	Effect.set_z_index(effect, -1)
