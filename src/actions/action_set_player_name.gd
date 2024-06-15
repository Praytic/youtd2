class_name ActionSetPlayerName


static func make(player_name: String) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SET_PLAYER_NAME,
		Action.Field.PLAYER_NAME: player_name,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var player_name: String = action[Action.Field.PLAYER_NAME]
	
	player.set_player_name(player_name)
