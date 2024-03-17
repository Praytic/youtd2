class_name DifficultyMenu extends PregameTab


var _difficulty: Difficulty.enm = Config.default_difficulty()


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func _on_generic_button_pressed(difficulty: Difficulty.enm):
	_difficulty = difficulty
	finished.emit()


func _on_beginner_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.BEGINNER)


func _on_easy_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.EASY)


func _on_medium_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.MEDIUM)


func _on_hard_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.HARD)


func _on_extreme_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.EXTREME)
