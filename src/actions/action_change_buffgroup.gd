class_name ActionChangeBuffgroup


static func make(tower_uid: int, buff_group: int, new_mode: BuffGroupMode.enm) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CHANGE_BUFFGROUP,
		Action.Field.UID: tower_uid,
		Action.Field.BUFFGROUP: buff_group,
		Action.Field.BUFFGROUP_MODE: new_mode,
		})

	return action


static func execute(action: Dictionary, _player: Player):
	var tower_uid: int = action[Action.Field.UID]
	var buff_group: int = action[Action.Field.BUFFGROUP]
	var new_mode: BuffGroupMode.enm = action[Action.Field.BUFFGROUP_MODE]

	var tower_node: Node = GroupManager.get_by_uid("towers", tower_uid)
	var tower: Tower = tower_node as Tower

	if tower == null:
		push_error("Failed to change buffgroup, tower is null.")

		return

	tower.set_buff_group_mode(buff_group, new_mode)
