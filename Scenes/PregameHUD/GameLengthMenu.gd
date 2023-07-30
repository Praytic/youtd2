extends VBoxContainer


signal finished(wave_count: int)


func _on_generic_button_pressed(wave_count: int):
	finished.emit(wave_count)


func _on_trial_button_pressed():
	_on_generic_button_pressed(80)


func _on_full_button_pressed():
	_on_generic_button_pressed(120)


func _on_neverending_button_pressed():
	_on_generic_button_pressed(240)
