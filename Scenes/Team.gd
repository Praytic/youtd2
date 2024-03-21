class_name Team extends Node

# Represents player's team. Two players per team.

# NOTE: Currently team is barely implemented. Will need to
# work on it for multiplayer.


var _id: int = -1
var _lives: float = 100
var _level: int = 1


#########################
###       Public      ###
#########################

func get_id() -> int:
	return _id


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


# Current level is the level of the last started wave.
# Starts at 0 and becomes 1 when the first wave starts.
# NOTE: Team.getLevel() in JASS
func get_level() -> int:
	return _level


func increment_level():
	_level += 1


#########################
###       Static      ###
#########################

static func make(id: int) -> Team:
	var team: Team = Preloads.team_scene.instantiate()
	team._id = id

	return team
