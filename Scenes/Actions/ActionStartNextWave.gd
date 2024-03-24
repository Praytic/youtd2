class_name ActionStartNextWave


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.START_NEXT_WAVE,
		})

	return action


static func execute(_action: Dictionary, player: Player, hud: HUD):
	var verify_ok: bool = ActionStartNextWave.verify(player)

	if !verify_ok:
		return

	var team: Team = player.get_team()
	team.start_next_wave()
	
	var local_player: Player = PlayerManager.get_local_player()
	var local_level: int = local_player.get_team().get_level()
	hud.update_level(local_level)
	var next_waves: Array[Wave] = local_player.get_next_5_waves()
	hud.show_wave_details(next_waves)


static func verify(player: Player) -> bool:
	var team: Team = player.get_team()
	var game_over: bool = team.is_game_over()
	if game_over:
		Messages.add_error(player, "Can't start next wave because the game is over.")

		return false
	
	var wave_is_in_progress: bool = player.wave_is_in_progress()
	if wave_is_in_progress:
		Messages.add_error(player, "Can't start next wave because a wave is in progress.")
		
		return false

	return true
	
