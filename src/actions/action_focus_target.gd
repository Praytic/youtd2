class_name ActionFocusTarget


static func make(target_uid: int, selected_tower_uid: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.FOCUS_TARGET,
		Action.Field.UID: target_uid,
		Action.Field.UID_2: selected_tower_uid,
		})

	return action


static func verify(player: Player, target: Unit, selected_tower: Tower) -> bool:
	if target == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_INVALID_TARGET"))

		return false

	if selected_tower != null:
		var player_match: bool = selected_tower.get_player() == player

		if !player_match:
			Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_TOWER"))

			return false

	return true


static func execute(action: Dictionary, player: Player):
	var target_uid: int = action[Action.Field.UID]
	var selected_tower_uid: int = action[Action.Field.UID_2]

	var target: Unit = GroupManager.get_by_uid("creeps", target_uid)
	var selected_tower: Unit = GroupManager.get_by_uid("towers", selected_tower_uid)

	var verify_ok: bool = ActionFocusTarget.verify(player, target, selected_tower)
	if !verify_ok:
		return

# 	1. If no tower is selected, then all player towers will
# 	   switch to the target.
# 	2. If a tower is selected, then only the selected tower
# 	   will switch to the target.
	var tower_list: Array[Tower]
	if selected_tower != null:
		tower_list = [selected_tower]
	else:
		tower_list = Utils.get_tower_list()

	for tower in tower_list:
		var player_match: bool = tower.get_player() == player

		if !player_match:
			continue

		tower.force_attack_target(target)

	var is_local_player: bool = player == PlayerManager.get_local_player()
	if is_local_player:
		player.create_focus_target_effect(target)
