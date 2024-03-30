class_name ConfigureSinglePlayerMenu extends VBoxContainer


signal cancel_pressed()
signal start_button_pressed()


@export var _game_mode_ui: GameModeUI


#########################
###     Built-in      ###
#########################

func _ready():
	pass


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
