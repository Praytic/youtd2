class_name CommandStartNextWave extends Command


static func make():
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.START_NEXT_WAVE,
		})

	return command
