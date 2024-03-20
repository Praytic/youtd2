extends Node


# NOTE: these settings are selected during game start. If
# they are accessed before that point, you will get these
# placeholders.
var _wave_count: int = 0
var _game_mode: GameMode.enm = GameMode.enm.BUILD
var _difficulty: Difficulty.enm = Difficulty.enm.EASY

# NOTE: you must use visual_rng for any code which is
# running only for local player. The global rng seed is
# reserved for code which runs for all players, to ensure
# determinism. A good example of where visual_rng should be
# used is FloatingText.
var visual_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func game_mode_is_random() -> bool:
	return Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return Globals.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
