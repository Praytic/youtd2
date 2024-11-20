class_name ConfigureSinglePlayerMenu extends PanelContainer


signal cancel_pressed()
signal start_button_pressed()


@export var _match_config_panel: MatchConfigPanel


#########################
###     Built-in      ###
#########################

func _ready():
	var cached_difficulty_string: String = Settings.get_setting(Settings.CACHED_GAME_DIFFICULTY)
	var cached_difficulty: Difficulty.enm = Difficulty.from_string(cached_difficulty_string)
	
	var cached_game_mode_string: String = Settings.get_setting(Settings.CACHED_GAME_MODE)
	var cached_game_mode: GameMode.enm = GameMode.from_string(cached_game_mode_string)
	
	var cached_game_length: int = Settings.get_setting(Settings.CACHED_GAME_LENGTH)

	_match_config_panel.set_difficulty(cached_difficulty)
	_match_config_panel.set_game_mode(cached_game_mode)
	_match_config_panel.set_game_length(cached_game_length)
	
	_match_config_panel.hide_team_mode_selector()


#########################
###       Public      ###
#########################

func get_difficulty() -> Difficulty.enm:
	return _match_config_panel.get_difficulty()


func get_game_length() -> int:
	return _match_config_panel.get_game_length()


func get_game_mode() -> GameMode.enm:
	return _match_config_panel.get_game_mode()


#########################
###     Callbacks     ###
#########################

func _on_start_button_pressed():
	start_button_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()
