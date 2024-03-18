extends Node


# NOTE: these settings are selected during game start. If
# they are accessed before that point, you will get these
# placeholders.
var _wave_count: int = 0
var _game_mode: GameMode.enm = GameMode.enm.BUILD


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func game_mode_is_random() -> bool:
	return Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return Globals.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
