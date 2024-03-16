extends Node


# Game settings
var _wave_count: int
var _game_mode: GameMode.enm
var _player_mode: PlayerMode.enm
var _difficulty: Difficulty.enm
var _tutorial_enabled: bool

var _builder_id: int
var _builder_instance: Builder
var _builder_range_bonus: float
var _builder_tower_lvl_bonus: int
var _builder_item_slots_bonus: int
var _builder_allows_adjacent_towers: bool


func reset():
	_wave_count = Config.default_wave_count()
	_game_mode = Config.default_game_mode()
	_player_mode = Config.default_player_mode()
	_difficulty = Config.default_difficulty()
	_tutorial_enabled = Config.default_tutorial_enabled()

	_builder_id = Config.default_builder_id()
	_builder_range_bonus = 0
	_builder_tower_lvl_bonus = 0
	_builder_item_slots_bonus = 0
	_builder_allows_adjacent_towers = true


func get_builder() -> Builder:
	return _builder_instance


func get_builder_range_bonus() -> float:
	return _builder_range_bonus


func get_builder_tower_lvl_bonus() -> int:
	return _builder_tower_lvl_bonus


func get_builder_item_slots_bonus() -> int:
	return _builder_item_slots_bonus


func get_builder_allows_adjacent_towers() -> bool:
	return _builder_allows_adjacent_towers


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
