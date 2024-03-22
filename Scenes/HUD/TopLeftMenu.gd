class_name TopLeftMenu extends PanelContainer


@export var _wave_status: WaveStatus
@export var _game_stats: GameStats


#########################
###       Public      ###
#########################

func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm):
	_game_stats.set_pregame_settings(wave_count, game_mode, difficulty)


func set_game_start_timer(timer: ManualTimer):
	_wave_status.set_game_start_timer(timer)


func set_next_wave_timer(timer: ManualTimer):
	_wave_status.set_next_wave_timer(timer)


func show_next_wave_button():
	_wave_status.show_next_wave_button()
	
	
func show_wave_details(wave_list: Array[Wave]):
	_wave_status.show_wave_details(wave_list)


func load_player_stats(local_player: Player, player_list: Array[Player]):
	_wave_status.load_player_stats(local_player)
	_game_stats.load_player_stats(player_list)


func set_game_time(time: float):
	_wave_status.set_game_time(time)


func set_local_builder_name(builder_name: String):
	_game_stats.set_local_builder_name(builder_name)
