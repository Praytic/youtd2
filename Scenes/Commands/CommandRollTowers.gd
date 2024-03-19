class_name CommandRollTowers extends Command


static func make():
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.ROLL_TOWERS,
		})

	return command
