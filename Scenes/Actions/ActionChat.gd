class_name ActionChat


static func make(chat_message_arg: String) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CHAT,
		Action.Field.CHAT_MESSAGE: chat_message_arg,
		})

	return action


static func execute(action: Dictionary, player: Player, hud: HUD, chat_commands: ChatCommands):
	var message: String = action[Action.Field.CHAT_MESSAGE]

	var is_chat_command: bool = !message.is_empty() && message[0] == "/"
	
	if is_chat_command:
		chat_commands.process_command(player, message)
	else:
		hud.add_chat_message(player.get_id(), message)
