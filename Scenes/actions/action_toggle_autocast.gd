class_name ActionToggleAutocast


static func make(autocast_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TOGGLE_AUTOCAST,
		Action.Field.UID: autocast_uid_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var autocast_uid: int = action[Action.Field.UID]

	var autocast_node: Node = GroupManager.get_by_uid("autocasts", autocast_uid)
	var autocast: Autocast = autocast_node as Autocast

	if autocast == null:
		Messages.add_error(player, "Failed to toggle autocast.")

		return

	autocast.toggle_auto_mode()
