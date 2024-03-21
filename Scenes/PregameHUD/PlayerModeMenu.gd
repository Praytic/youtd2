class_name PlayerModeMenu extends PregameTab


var _player_mode: PlayerMode.enm

@export var _coop_button: Button


#########################
###     Built-in      ###
#########################

# NOTE: disable coop button in released game builds because
# multiplayer is not ready.
func _ready():
	_coop_button.disabled = !Config.enable_coop_button()


#########################
###       Public      ###
#########################

func get_player_mode() -> PlayerMode.enm:
	return _player_mode



#########################
###     Callbacks     ###
#########################

func _on_generic_button_pressed(player_mode: PlayerMode.enm):
	_player_mode = player_mode
	finished.emit()


func _on_single_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.SINGLE)


func _on_coop_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.COOP)
