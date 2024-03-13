extends PregameTab


signal finished()


func _on_generic_button_pressed(wave_count: int):
	Globals._wave_count = wave_count
	finished.emit()


func _on_trial_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_TRIAL)


func _on_full_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_FULL)


func _on_neverending_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_NEVERENDING)
