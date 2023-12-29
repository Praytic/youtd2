extends VBoxContainer


signal finished(player_mode: PlayerMode.enm)


func _on_generic_button_pressed(player_mode: PlayerMode.enm):
	finished.emit(player_mode)


func _on_single_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.SINGLE)


func _on_coop_button_pressed():
	_on_generic_button_pressed(PlayerMode.enm.COOP)
