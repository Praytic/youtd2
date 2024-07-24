class_name ActionChangeBuffgroup


static func make(tower_uid: int, buff_group: int, new_mode: BuffGroupMode.enm) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CHANGE_BUFFGROUP,
		Action.Field.UID: tower_uid,
		Action.Field.BUFFGROUP: buff_group,
		Action.Field.BUFFGROUP_MODE: new_mode,
		})

	return action


static func verify(player: Player, tower: Tower) -> bool:
	if tower == null:
		Utils.add_ui_error(player, "Failed to change buffgroup")

		return false

	var player_match: bool = tower.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, "You don't own this tower")

		return false

	return true


static func execute(action: Dictionary, player: Player):
	var tower_uid: int = action[Action.Field.UID]
	var buff_group: int = action[Action.Field.BUFFGROUP]
	var new_mode: BuffGroupMode.enm = action[Action.Field.BUFFGROUP_MODE]

	var tower_node: Node = GroupManager.get_by_uid("towers", tower_uid)
	var tower: Tower = tower_node as Tower

	var verify_ok: bool = ActionChangeBuffgroup.verify(player, tower)
	if !verify_ok:
		return

	tower.set_buff_group_mode(buff_group, new_mode)
