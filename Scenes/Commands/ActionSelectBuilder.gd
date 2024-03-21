class_name ActionSelectBuilder extends Action



var builder_id: int:
	get:
		return _data[Action.Field.BUILDER_ID]


static func make(builder_id_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_BUILDER,
		Action.Field.BUILDER_ID: builder_id_arg,
		})

	return action
