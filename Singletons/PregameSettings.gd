extends Node


# This is storage for settings which are selected by the
# player when the game first starts. The settings are
# selected via the PregameHUD scene. This values are set
# once and never changed after that.


var _wave_count: int
var _game_mode: GameMode.enm
var _player_mode: PlayerMode.enm
var _difficulty: Difficulty.enm
var _builder_id: int
var _tutorial_enabled: bool


# NOTE: these default values will be used if pregame menu is
# skipped. These values must be set in _ready() to avoid
# problems with order of Singleton initializations.
func reset():
	_wave_count = Config.default_wave_count()
	_game_mode = Config.default_game_mode()
	_player_mode = Config.default_player_mode()
	_difficulty = Config.default_difficulty()
	_builder_id = Config.default_builder_id()
	_tutorial_enabled = Config.default_tutorial_enabled()


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
	return PregameSettings.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || PregameSettings.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return PregameSettings.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
