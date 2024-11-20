class_name CreateOnlineMatchMenu extends PanelContainer


signal cancel_pressed()
signal create_pressed()


@export var _match_config_panel: MatchConfigPanel


#########################
###       Public      ###
#########################

func get_match_config() -> MatchConfig:
	var match_config: MatchConfig = _match_config_panel.get_match_config()
	
	return match_config


#########################
###     Callbacks     ###
#########################

func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_button_pressed():
	create_pressed.emit()
