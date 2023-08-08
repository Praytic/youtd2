extends VBoxContainer


signal finished(tutorial_enabled: bool)


func _on_generic_button_pressed(tutorial_enabled: bool):
	finished.emit(tutorial_enabled)


func _on_yes_button_pressed():
	_on_generic_button_pressed(true)


func _on_no_button_pressed():
	_on_generic_button_pressed(false)
