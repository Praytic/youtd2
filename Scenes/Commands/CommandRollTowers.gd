class_name ActionRollTowers extends Action


static func make():
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.ROLL_TOWERS,
		})

	return action
