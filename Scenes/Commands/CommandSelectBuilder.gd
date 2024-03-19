class_name CommandSelectBuilder extends Command



var builder_id: int:
	get:
		return _data[Command.Field.BUILDER_ID]


static func make(builder_id_arg: int):
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.SELECT_BUILDER,
		Command.Field.BUILDER_ID: builder_id_arg,
		})

	return command
