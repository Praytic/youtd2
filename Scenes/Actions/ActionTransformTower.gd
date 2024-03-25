class_name ActionTransformTower


static func make(tower_id_arg: int, global_pos_arg: Vector2) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSFORM_TOWER,
		Action.Field.TOWER_ID: tower_id_arg,
		Action.Field.POSITION: global_pos_arg,
		})

	return action


static func execute(action: Dictionary, player: Player, map: Map):
	var new_tower_id: int = action[Action.Field.TOWER_ID]
	var global_pos: Vector2 = action[Action.Field.POSITION]
	
	var enough_resources: bool = BuildTower.enough_resources_for_tower(new_tower_id, player)

	if !enough_resources:
		BuildTower.add_error_about_building_tower(new_tower_id, player)

		return

	var tower_stash: TowerStash = player.get_tower_stash()
	var tower_exists_in_stash: bool = tower_stash.has_tower(new_tower_id)
	if !tower_exists_in_stash:
		Messages.add_error(player, "You don't have this tower")

		return

	var can_transform: bool = map.can_transform_at_pos(global_pos)

	if !can_transform:
		Messages.add_error(player, "Can't transform here.")

		return
	
	var clamped_pos: Vector2 = map.get_pos_on_tilemap_clamped(global_pos)
	var prev_tower: Tower = Utils.get_tower_at_position(clamped_pos)

	player.remove_food_for_tower(prev_tower.get_id())
	player.add_food_for_tower(new_tower_id)

	var new_tower: Tower = Tower.make(new_tower_id, player, prev_tower)
	new_tower.position = prev_tower.position
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
