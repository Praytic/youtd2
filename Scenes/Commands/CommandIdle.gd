class_name CommandIdle extends Command


static func make():
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.IDLE,
		})

	return command
