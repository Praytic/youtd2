class_name ActionTransmute


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSMUTE,
		})

	return action


static func execute(_action: Dictionary, player: Player):
	HoradricCube.transmute(player)
