class_name ConfigureSinglePlayerMenu extends VBoxContainer


signal cancel_pressed()
signal start_button_pressed()


@export var _game_mode_ui: GameModeUI


#########################
###     Built-in      ###
#########################

func _ready():
	var cached_difficulty_string: String = Settings.get_setting(Settings.CACHED_GAME_DIFFICULTY)
	var cached_difficulty: Difficulty.enm = Difficulty.from_string(cached_difficulty_string)
	
	var cached_game_mode_string: String = Settings.get_setting(Settings.CACHED_GAME_MODE)
	var cached_game_mode: GameMode.enm = GameMode.from_string(cached_game_mode_string)
	
	var cached_game_length: int = Settings.get_setting(Settings.CACHED_GAME_LENGTH)

	_game_mode_ui.set_difficulty(cached_difficulty)
	_game_mode_ui.set_game_mode(cached_game_mode)
	_game_mode_ui.set_game_length(cached_game_length)


#########################
###       Public      ###
#########################

func get_difficulty() -> Difficulty.enm:
	return _game_mode_ui.get_difficulty()


func get_game_length() -> int:
	return _game_mode_ui.get_game_length()


func get_game_mode() -> GameMode.enm:
	return _game_mode_ui.get_game_mode()


#########################
###     Callbacks     ###
#########################

func _on_start_button_pressed():
	start_button_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()
