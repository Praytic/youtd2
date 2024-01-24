extends Node


# This is storage for settings which are selected by the
# player when the game first starts. This values are set
# once and never changed after that.


# Emitted when player has finished choosing pregame
# settings. Settings values can be used after this point.
signal finalized()


var _wave_count: int
var _game_mode: GameMode.enm
var _player_mode: PlayerMode.enm
var _difficulty: Difficulty.enm
var _builder: Builder.enm
var _tutorial_enabled: bool


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_player_mode() -> PlayerMode.enm:
	return _player_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_builder() -> Builder.enm:
	return _builder


func get_tutorial_enabled() -> bool:
	return _tutorial_enabled


func game_mode_is_random() -> bool:
	return PregameSettings.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || PregameSettings.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return PregameSettings.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
