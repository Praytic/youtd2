class_name ActionIdle extends Action


static func make():
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.IDLE,
		})

	return action
