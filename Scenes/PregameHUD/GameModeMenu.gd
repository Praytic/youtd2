extends VBoxContainer


signal finished(game_mode: GameMode.enm)


func _on_generic_button_pressed(game_mode: GameMode.enm):
	finished.emit(game_mode)


func _on_build_button_pressed():
	_on_generic_button_pressed(GameMode.enm.BUILD)


func _on_random_button_pressed():
	_on_generic_button_pressed(GameMode.enm.RANDOM_WITH_UPGRADES)


func _on_totally_random_button_pressed():
	_on_generic_button_pressed(GameMode.enm.TOTALLY_RANDOM)
