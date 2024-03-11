extends Node


var _portal_lives: float


func reset():
	_portal_lives = 100


func get_current() -> float:
	return _portal_lives


func get_lives_string() -> String:
	var lives_string: String = Utils.format_percent(floori(_portal_lives) / 100.0, 2)

	return lives_string


func modify_portal_lives(amount: float):
	_portal_lives = max(0.0, _portal_lives + amount)

	if Config.unlimited_portal_lives() && _portal_lives == 0:
		_portal_lives = 1
