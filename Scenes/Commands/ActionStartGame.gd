class_name ActionStartGame extends Action


static func make():
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.START_GAME,
		})

	return action
