class_name ActionStartNextWave extends Action


static func make():
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.START_NEXT_WAVE,
		})

	return action
