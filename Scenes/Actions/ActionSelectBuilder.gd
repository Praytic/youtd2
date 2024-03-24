class_name ActionSelectBuilder



static func make(builder_id_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_BUILDER,
		Action.Field.BUILDER_ID: builder_id_arg,
		})

	return action


static func execute(action: Dictionary, player: Player, hud: HUD):
	var builder_id: int = action[Action.Field.BUILDER_ID]
	
	player.set_builder(builder_id)

	var local_player: Player = PlayerManager.get_local_player()

	if player == local_player:
		var local_builder: Builder = local_player.get_builder()
		var local_builder_name: String = local_builder.get_display_name()
		hud.set_local_builder_name(local_builder_name)

		if local_builder.get_adds_extra_recipes():
			hud.enable_extra_recipes()
