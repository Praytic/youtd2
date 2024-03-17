class_name TutorialQuestionMenu extends PregameTab


var _tutorial_enabled: bool = Config.default_tutorial_enabled()


func get_tutorial_enabled() -> bool:
	return _tutorial_enabled


func _on_generic_button_pressed(tutorial_enabled: bool):
	_tutorial_enabled = tutorial_enabled
	finished.emit()


func _on_yes_button_pressed():
	_on_generic_button_pressed(true)


func _on_no_button_pressed():
	_on_generic_button_pressed(false)
