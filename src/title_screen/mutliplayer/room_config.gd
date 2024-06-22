class_name RoomConfig


enum Field {
	GAME_MODE,
	DIFFICULTY,
	GAME_LENGTH,
	COUNT,
}

# Stores config values for a game room.


var _game_mode: GameMode.enm = GameMode.enm.BUILD
var _difficulty: Difficulty.enm = Difficulty.enm.BEGINNER
var _game_length: int = Constants.WAVE_COUNT_FULL


#########################
###     Built-in      ###
#########################

func _init(game_mode: GameMode.enm, difficulty: Difficulty.enm, game_length: int):
	_game_mode = game_mode
	_difficulty = difficulty
	_game_length = game_length


#########################
###       Public      ###
#########################

func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_game_length() -> int:
	return _game_length


func get_game_mode() -> GameMode.enm:
	return _game_mode


# TODO: fix this code being duplicated here and in GameStats
func get_display_string() -> String:
	var game_length_string: String = _get_game_length_string(_game_length)
	var game_mode_string: String = GameMode.convert_to_display_string(_game_mode).capitalize()
	var difficulty_string: String = Difficulty.convert_to_string(_difficulty).capitalize()
	
	var display_string: String = "%s, %s, %s\n" % [game_length_string, game_mode_string, difficulty_string]
	
	return display_string


func get_display_string_rich() -> String:
	var game_length_string: String = _get_game_length_string(_game_length)
	var game_mode_string: String = GameMode.convert_to_display_string(_game_mode).capitalize()
	var difficulty_string: String = Difficulty.convert_to_colored_string(_difficulty)
	
	var display_string: String = "[color=GOLD]%s[/color], [color=GOLD]%s[/color], %s\n" % [game_length_string, game_mode_string, difficulty_string]
	
	return display_string


func convert_to_bytes() -> PackedByteArray:
	var dict: Dictionary = {}
	dict[Field.DIFFICULTY] = _difficulty
	dict[Field.GAME_MODE] = _game_mode
	dict[Field.GAME_LENGTH] = _game_length
	var bytes: PackedByteArray = var_to_bytes(dict)
	
	return bytes


static func convert_from_bytes(bytes: PackedByteArray) -> RoomConfig:
	var dict: Dictionary = Utils.convert_bytes_to_dict(bytes)
	
	var dict_is_valid: bool = Utils.check_dict_has_fields(dict, Field.COUNT)
	if !dict_is_valid:
		return null
	
	var game_mode: GameMode.enm = int(dict[Field.GAME_MODE]) as GameMode.enm
	var difficulty: Difficulty.enm = int(dict[Field.DIFFICULTY]) as Difficulty.enm
	var game_length: int = int(dict[Field.GAME_LENGTH])
	var room_config: RoomConfig = RoomConfig.new(game_mode, difficulty, game_length)
	
	return room_config


#########################
###      Private      ###
#########################


func _get_game_length_string(wave_count: int) -> String:
	var game_length_string: String

	match wave_count:
		Constants.WAVE_COUNT_TRIAL: game_length_string = "Trial"
		Constants.WAVE_COUNT_FULL: game_length_string = "Full"
		Constants.WAVE_COUNT_NEVERENDING: game_length_string = "Neverending"
		_: "Unknown"

	return game_length_string
