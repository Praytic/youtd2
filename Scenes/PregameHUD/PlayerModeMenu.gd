class_name PlayerModeMenu extends PregameTab


var _player_mode: PlayerMode.enm = PlayerMode.enm.SINGLE


func get_player_mode() -> PlayerMode.enm:
	return _player_mode


func _on_generic_button_pressed(player_mode: PlayerMode.enm):
	_player_mode = player_mode
	finished.emit()


func _on_single_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.SINGLE)


func _on_coop_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.COOP)
