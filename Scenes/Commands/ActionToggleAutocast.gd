class_name ActionToggleAutocast extends Action


var autocast_uid: int:
	get:
		return _data[Action.Field.UID]


static func make(autocast_uid_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TOGGLE_AUTOCAST,
		Action.Field.UID: autocast_uid_arg,
		})

	return action
