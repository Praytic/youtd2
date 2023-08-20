extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


enum Tab {
	GAME_LENGTH,
	DISTRIBUTION,
	DIFFICULTY,
	TUTORIAL_QUESTION,
}


signal finished(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm)

var _wave_count: int
var _game_mode: GameMode.enm
var _difficulty: Difficulty.enm
var _tutorial_enabled: bool


@export var _tab_container: TabContainer


func _ready():
	_tab_container.current_tab = Tab.GAME_LENGTH


func _on_game_length_menu_finished(wave_count: int):
	_wave_count = wave_count
	_tab_container.current_tab = Tab.DISTRIBUTION


func _on_game_mode_menu_finished(game_mode: GameMode.enm):
	_game_mode = game_mode
	_tab_container.current_tab = Tab.DIFFICULTY


func _on_difficulty_menu_finished(difficulty: Difficulty.enm):
	_difficulty = difficulty
	
	_tab_container.current_tab = Tab.TUTORIAL_QUESTION



func _on_tutorial_question_menu_finished(tutorial_enabled: bool):
	_tutorial_enabled = tutorial_enabled
	
	finished.emit(_wave_count, _game_mode, _difficulty, _tutorial_enabled)
