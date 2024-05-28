class_name TopLeftMenu extends PanelContainer


@export var _wave_status: WaveStatus
@export var _game_stats: GameStats


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	_wave_status.connect_to_local_player(local_player)
	_game_stats.connect_to_local_player(local_player)


func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm):
	_game_stats.set_pregame_settings(wave_count, game_mode, difficulty)


func set_game_start_timer(timer: ManualTimer):
	_wave_status.set_game_start_timer(timer)


func show_next_wave_button():
	_wave_status.show_next_wave_button()
