class_name ActionIdle


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.IDLE,
		})

	return action
