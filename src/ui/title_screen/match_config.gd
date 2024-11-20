class_name MatchConfig


enum Field {
	GAME_MODE,
	DIFFICULTY,
	GAME_LENGTH,
	TEAM_MODE,
	COUNT,
}

# Stores config values for a game match.


var _game_mode: GameMode.enm = GameMode.enm.BUILD
var _difficulty: Difficulty.enm = Difficulty.enm.BEGINNER
var _game_length: int = Constants.WAVE_COUNT_FULL
var _team_mode: TeamMode.enm = TeamMode.enm.ONE_PLAYER_PER_TEAM


const KEY_DIFFICULTY: String = "difficulty"
const KEY_GAME_MODE: String = "game_mode"
const KEY_GAME_LENGTH: String = "game_length"
const KEY_TEAM_MODE: String = "team_mode"


#########################
###     Built-in      ###
#########################

func _init(game_mode: GameMode.enm, difficulty: Difficulty.enm, game_length: int, team_mode: TeamMode.enm):
	_game_mode = game_mode
	_difficulty = difficulty
	_game_length = game_length
	_team_mode = team_mode


#########################
###       Public      ###
#########################

func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_game_length() -> int:
	return _game_length


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_team_mode() -> TeamMode.enm:
	return _team_mode


func get_display_string_rich() -> String:
	var display_string: String = MatchConfig.convert_configs_to_string(_game_length, _game_mode, _difficulty, _team_mode)
	
	return display_string


func convert_to_bytes() -> PackedByteArray:
	var dict: Dictionary = {}
	dict[Field.DIFFICULTY] = _difficulty
	dict[Field.GAME_MODE] = _game_mode
	dict[Field.GAME_LENGTH] = _game_length
	dict[Field.TEAM_MODE] = _team_mode
	var bytes: PackedByteArray = var_to_bytes(dict)
	
	return bytes


static func convert_from_bytes(bytes: PackedByteArray) -> MatchConfig:
	var dict: Dictionary = Utils.convert_bytes_to_dict(bytes)
	
	var dict_is_valid: bool = Utils.check_dict_has_fields(dict, Field.COUNT)
	if !dict_is_valid:
		return null
	
	var game_mode: GameMode.enm = int(dict[Field.GAME_MODE]) as GameMode.enm
	var difficulty: Difficulty.enm = int(dict[Field.DIFFICULTY]) as Difficulty.enm
	var game_length: int = int(dict[Field.GAME_LENGTH])
	var team_mode: TeamMode.enm = int(dict[Field.TEAM_MODE]) as TeamMode.enm
	var match_config: MatchConfig = MatchConfig.new(game_mode, difficulty, game_length, team_mode)
	
	return match_config


func convert_to_dict() -> Dictionary:
	var dict: Dictionary = {}
	var difficulty_string: String = Difficulty.convert_to_string(_difficulty)
	var game_mode_string: String = GameMode.convert_to_string(_game_mode)
	var game_length_string: String = str(_game_length)
	var team_mode_string: String = TeamMode.convert_to_string(_team_mode)
	dict[KEY_DIFFICULTY] = difficulty_string
	dict[KEY_GAME_MODE] = game_mode_string
	dict[KEY_GAME_LENGTH] = game_length_string
	dict[KEY_TEAM_MODE] = team_mode_string
	
	return dict


static func convert_from_dict(dict: Dictionary) -> MatchConfig:
	var game_mode_string: String = dict.get(KEY_GAME_MODE, "")
	var game_mode: GameMode.enm = GameMode.from_string(game_mode_string)
	var difficulty_string: String = dict.get(KEY_DIFFICULTY, "")
	var difficulty: Difficulty.enm = Difficulty.from_string(difficulty_string)
	var game_length: int = dict.get(KEY_GAME_LENGTH, Constants.WAVE_COUNT_TRIAL) as int
	var team_mode_string: String = dict.get(KEY_TEAM_MODE, "")
	var team_mode: TeamMode.enm = TeamMode.from_string(team_mode_string)
	var match_config: MatchConfig = MatchConfig.new(game_mode, difficulty, game_length, team_mode)
	
	return match_config


static func convert_configs_to_string(game_length: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, team_mode: TeamMode.enm) -> String:
	var game_length_string: String = _get_game_length_string(game_length)
	var game_mode_string: String = GameMode.convert_to_display_string(game_mode).capitalize()
	var difficulty_string: String = Difficulty.convert_to_colored_string(difficulty)
	var team_mode_string: String = TeamMode.convert_to_display_string(team_mode)
	
	var display_string: String = "[color=GOLD]%s[/color], [color=GOLD]%s[/color], %s, %s\n" % [game_length_string, game_mode_string, difficulty_string, team_mode_string]
	
	return display_string


static func _get_game_length_string(wave_count: int) -> String:
	var game_length_string: String

	match wave_count:
		Constants.WAVE_COUNT_TRIAL: game_length_string = "Trial"
		Constants.WAVE_COUNT_FULL: game_length_string = "Full"
		Constants.WAVE_COUNT_NEVERENDING: game_length_string = "Neverending"
		_: "Unknown"

	return game_length_string
