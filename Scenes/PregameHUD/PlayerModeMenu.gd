extends VBoxContainer


signal finished()


func _on_generic_button_pressed(player_mode: PlayerMode.enm):
	PregameSettings._player_mode = player_mode
	finished.emit()


func _on_single_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.SINGLE)


func _on_coop_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.COOP)
