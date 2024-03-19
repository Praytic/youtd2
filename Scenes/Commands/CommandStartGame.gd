class_name CommandStartGame extends Command


static func make():
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.START_GAME,
		})

	return command
