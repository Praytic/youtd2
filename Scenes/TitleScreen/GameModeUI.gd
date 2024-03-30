class_name GameModeUI extends GridContainer


@export var _difficulty_combo: OptionButton
@export var _game_length_combo: OptionButton
@export var _game_mode_combo: OptionButton


func set_disabled(value: bool):
	_difficulty_combo.disabled = value
	_game_length_combo.disabled = value
	_game_mode_combo.disabled = value


func get_difficulty() -> Difficulty.enm:
	var selected_index: int = _difficulty_combo.get_selected()
	var difficulty: Difficulty.enm = selected_index as Difficulty.enm
	
	return difficulty


func get_game_length() -> int:
	var selected_index: int = _game_length_combo.get_selected()
	var game_length: int
	match selected_index:
		0: game_length = Constants.WAVE_COUNT_TRIAL
		1: game_length = Constants.WAVE_COUNT_FULL
		2: game_length = Constants.WAVE_COUNT_NEVERENDING
		_:
			push_error("Unknown game length combo index: ", selected_index)
			game_length = Constants.WAVE_COUNT_TRIAL
	
	return game_length


func get_game_mode() -> GameMode.enm:
	var selected_index: int = _game_mode_combo.get_selected()
	var game_mode: GameMode.enm = selected_index as GameMode.enm
	
	return game_mode
