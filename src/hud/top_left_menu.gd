class_name TopLeftMenu extends PanelContainer


@export var _wave_status: WaveStatus
@export var _game_stats: GameStats


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	_wave_status.connect_to_local_player(local_player)
	_game_stats.connect_to_local_player(local_player)


func set_game_start_timer(timer: ManualTimer):
	_wave_status.set_game_start_timer(timer)
