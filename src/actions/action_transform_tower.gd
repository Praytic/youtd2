class_name ActionTransformTower


static func make(prev_tower_uid: int, new_tower_id: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSFORM_TOWER,
		Action.Field.UID: prev_tower_uid,
		Action.Field.TOWER_ID: new_tower_id,
		})

	return action


static func verify(player: Player, prev_tower: Tower, new_tower_id: int) -> bool:
	if prev_tower == null:
		Utils.add_ui_error(player, "Failed to upgrade")

		return false

	var player_match: bool = prev_tower.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, "You don't own this tower")
		
		return false

	var tower_stash: TowerStash = player.get_tower_stash()
	var tower_exists_in_stash: bool = tower_stash.has_tower(new_tower_id)
	if !tower_exists_in_stash:
		Utils.add_ui_error(player, "You don't have this tower in stash")

		return false

	var enough_resources: bool = BuildTower.enough_resources_for_tower(new_tower_id, player)
	if !enough_resources:
		BuildTower.add_error_about_building_tower(new_tower_id, player)

		return false

	var game_mode_allows_transform: bool = Globals.game_mode_allows_transform()
	if !game_mode_allows_transform:
		Utils.add_ui_error(player, "Can't transform in build mode")

		return false

	var transform_is_allowed: bool = prev_tower.get_transform_is_allowed()
	if !transform_is_allowed:
		Utils.add_ui_error(player, "Can't transform right now")

		return false

	return true


static func execute(action: Dictionary, player: Player):
	var new_tower_id: int = action[Action.Field.TOWER_ID]
	var prev_tower_uid: int = action[Action.Field.UID]
	var prev_tower_node: Node = GroupManager.get_by_uid("towers", prev_tower_uid)
	var prev_tower: Tower = prev_tower_node as Tower

	var verify_ok: bool = ActionTransformTower.verify(player, prev_tower, new_tower_id)
	if !verify_ok:
		return

	player.remove_food_for_tower(prev_tower.get_id())
	player.add_food_for_tower(new_tower_id)

# 	NOTE: order is important here. Need to set position
# 	before adding to world so that correct position can be
# 	accessed in tower's on_create().
	var new_tower: Tower = Tower.make(new_tower_id, player, prev_tower)
	var prev_tower_pos: Vector2 = prev_tower.get_position_wc3_2d()
	new_tower.set_position_wc3_2d(prev_tower_pos)
	Utils.add_object_to_world(new_tower)

#	Refund build cost for previous tower
	var refund_value: int = ActionTransformTower.get_transform_refund(prev_tower.get_id(), new_tower_id)
	prev_tower.get_player().give_gold(refund_value, prev_tower, false, true)

#	Spend build cost for new tower
	var build_cost: float = TowerProperties.get_cost(new_tower_id)
	player.spend_gold(build_cost)

# 	NOTE: don't modify tome count because transform is
# 	enabled only in random modes and tome costs are 0 in
# 	random mode

	prev_tower.remove_from_game()

	var tower_stash: TowerStash = player.get_tower_stash()
	tower_stash.spend_tower(new_tower_id)


# This is the value refunded when a tower is transformed
# into another tower
static func get_transform_refund(prev_tower_id: int, new_tower_id: int) -> int:
	var prev_cost: int = TowerProperties.get_cost(prev_tower_id)
	var prev_family: int = TowerProperties.get_family(prev_tower_id)
	var new_family: int = TowerProperties.get_family(new_tower_id)
	var family_is_same: bool = prev_family == new_family

	var transform_refund: int

	if family_is_same:
		transform_refund = floori(prev_cost * 1.0)
	else:
		transform_refund = floori(prev_cost * 0.75)

	return transform_refund
