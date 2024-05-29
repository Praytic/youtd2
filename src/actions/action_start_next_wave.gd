class_name ActionStartNextWave


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.START_NEXT_WAVE,
		})

	return action


static func execute(_action: Dictionary, player: Player):
	var verify_ok: bool = ActionStartNextWave.verify(player)

	if !verify_ok:
		return

	var team: Team = player.get_team()
	team.start_next_wave()


static func verify(player: Player) -> bool:
	var team: Team = player.get_team()
	var team_finished_the_game: bool = team.finished_the_game()
	if team_finished_the_game:
		Messages.add_error(player, "Can't start next wave because the game is over.")

		return false

	var current_level: int = player.get_team().get_level()
	var wave_count: int = Globals.get_wave_count()
	var reached_last_wave: bool = current_level == wave_count
	var game_is_neverending: bool = Globals.game_is_neverending()
	if reached_last_wave && !game_is_neverending:
		Messages.add_error(player, "There are no more waves.")

		return false

	var wave_is_in_progress: bool = player.wave_is_in_progress()
	if wave_is_in_progress:
		Messages.add_error(player, "Can't start next wave because a wave is in progress.")
		
		return false

	return true
	
