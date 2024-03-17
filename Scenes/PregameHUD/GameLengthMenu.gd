class_name GameLengthMenu extends PregameTab


var _game_length: int


func get_game_length() -> int:
	return _game_length


func _on_generic_button_pressed(wave_count: int):
	_game_length = wave_count
	finished.emit()


func _on_trial_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_TRIAL)


func _on_full_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_FULL)


func _on_neverending_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_NEVERENDING)
