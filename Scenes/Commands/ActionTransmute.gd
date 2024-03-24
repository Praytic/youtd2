class_name ActionTransmute extends Action


static func make():
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSMUTE,
		})

	return action
