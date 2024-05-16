class_name ActionSelectBuilder



static func make(builder_id_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_BUILDER,
		Action.Field.BUILDER_ID: builder_id_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var builder_id: int = action[Action.Field.BUILDER_ID]
	
	player.set_builder(builder_id)
