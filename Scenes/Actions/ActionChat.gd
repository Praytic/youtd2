class_name ActionChat extends Action


var chat_message: String:
	get:
		return _data[Action.Field.CHAT_MESSAGE]


static func make(chat_message_arg: String):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CHAT,
		Action.Field.CHAT_MESSAGE: chat_message_arg,
		})

	return action
