class_name TopLeftMenu extends PanelContainer


@export var _game_stats: GameStats


func set_gold(gold: float):
	_game_stats.set_gold(gold)


func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, builder_id: int):
	_game_stats.set_pregame_settings(wave_count, game_mode, difficulty, builder_id)
