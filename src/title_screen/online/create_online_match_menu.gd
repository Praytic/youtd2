class_name CreateOnlineMatchMenu extends PanelContainer


signal cancel_pressed()
signal create_pressed()


@export var _game_mode_ui: GameModeUI


#########################
###       Public      ###
#########################

func get_match_config() -> RoomConfig:
	var match_config: RoomConfig = _game_mode_ui.get_room_config()
	
	return match_config


#########################
###     Callbacks     ###
#########################

func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_button_pressed():
	create_pressed.emit()
