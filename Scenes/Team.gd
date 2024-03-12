class_name Team

# Represents player's team. Two players per team.

# NOTE: Currently team is barely implemented. Will need to
# work on it for multiplayer.


signal lives_changed()


var _lives: float = 100


# NOTE: Team.getLivesPercent() in JASS
func get_lives_percent() -> float:
	return _lives


func get_lives_string() -> String:
	var lives_string: String = Utils.format_percent(floori(_lives) / 100.0, 2)

	return lives_string


func modify_lives(amount: float):
	_lives = max(0.0, _lives + amount)

	if Config.unlimited_portal_lives() && _lives == 0:
		_lives = 1

	lives_changed.emit()


# NOTE: Team.getLevel() in JASS
func get_level() -> int:
	return WaveLevel.get_current()


func increment_level():
	WaveLevel.increase()
