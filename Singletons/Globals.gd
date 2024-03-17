extends Node


# Game settings
var _wave_count: int
var _game_mode: GameMode.enm
var _player_mode: PlayerMode.enm
var _difficulty: Difficulty.enm
var _tutorial_enabled: bool
var _builder_id: int


func reset():
	_wave_count = Config.default_wave_count()
	_game_mode = Config.default_game_mode()
	_player_mode = Config.default_player_mode()
	_difficulty = Config.default_difficulty()
	_tutorial_enabled = Config.default_tutorial_enabled()
	_builder_id = Config.default_builder_id()


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_player_mode() -> PlayerMode.enm:
	return _player_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_builder_id() -> int:
	return _builder_id


func get_tutorial_enabled() -> bool:
	return _tutorial_enabled


func game_mode_is_random() -> bool:
	return Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return Globals.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
