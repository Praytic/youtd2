extends VBoxContainer


signal finished(wave_count: int)


func _on_generic_button_pressed(wave_count: int):
	finished.emit(wave_count)


func _on_trial_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_TRIAL)


func _on_full_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_FULL)


func _on_neverending_button_pressed():
	_on_generic_button_pressed(Constants.WAVE_COUNT_NEVERENDING)
