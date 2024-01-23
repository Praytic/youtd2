extends Node


var _portal_lives: float = 100.0


func get_current() -> float:
	return _portal_lives


func get_lives_string() -> String:
	var lives_string: String = Utils.format_percent(floori(_portal_lives) / 100.0, 2)

	return lives_string


func deal_damage(damage: float):
	if not Config.unlimited_portal_lives():
		_portal_lives = max(0.0, _portal_lives - damage)

	if _portal_lives == 0.0 && !Globals.game_over:
		Messages.add_normal("[color=RED]The portal has been destroyed! The game is over.[/color]")
		Globals.game_over = true
		EventBus.game_over.emit()


func modify_portal_lives(amount: float):
	_portal_lives += amount
