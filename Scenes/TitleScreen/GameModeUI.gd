class_name GameModeUI extends GridContainer


var _combo_index_to_game_length: Dictionary = {
	0: Constants.WAVE_COUNT_TRIAL,
	1: Constants.WAVE_COUNT_FULL,
	2: Constants.WAVE_COUNT_NEVERENDING,
}

@export var _difficulty_combo: OptionButton
@export var _game_length_combo: OptionButton
@export var _game_mode_combo: OptionButton


func set_difficulty(difficulty: Difficulty.enm):
	_difficulty_combo.select(difficulty)


func set_game_mode(game_mode: GameMode.enm):
	_game_mode_combo.select(game_mode)


func set_game_length(game_length: int):
	var combo_index = _combo_index_to_game_length.find_key(game_length)

	if combo_index == null:
		push_error("Invalid game length: %d" % game_length)

		return
	
	_game_length_combo.select(combo_index)


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
	var game_length: int = _combo_index_to_game_length[selected_index]
	
	return game_length


func get_game_mode() -> GameMode.enm:
	var selected_index: int = _game_mode_combo.get_selected()
	var game_mode: GameMode.enm = selected_index as GameMode.enm
	
	return game_mode
