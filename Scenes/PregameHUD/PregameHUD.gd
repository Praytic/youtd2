extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


enum Tab {
	GAME_LENGTH,
	DIFFICULTY,
}


signal finished(wave_count: int, difficulty: Difficulty.enm)

var _wave_count: int
var _difficulty: Difficulty.enm


@onready var _tab_container: TabContainer = $TabContainer


func _ready():
	_tab_container.current_tab = Tab.GAME_LENGTH


func _on_game_length_menu_finished(wave_count: int):
	_wave_count = wave_count
	
	var default_difficulty: Difficulty.enm = Config.default_difficulty()
	var difficulty_is_predefined: bool = default_difficulty != Difficulty.enm.NONE

	if difficulty_is_predefined:
#		Skip difficulty menu
		_on_difficulty_menu_finished(default_difficulty)
	else:
		_tab_container.current_tab = Tab.DIFFICULTY


func _on_difficulty_menu_finished(difficulty: Difficulty.enm):
	_difficulty = difficulty
	
	finished.emit(_wave_count, _difficulty)
