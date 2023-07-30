extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


enum Tab {
	GAME_LENGTH,
	DISTRIBUTION,
	DIFFICULTY,
}


signal finished(wave_count: int, distribution: Distribution.enm, difficulty: Difficulty.enm)

var _wave_count: int
var _distribution: Distribution.enm
var _difficulty: Difficulty.enm


@onready var _tab_container: TabContainer = $TabContainer


func _ready():
	_tab_container.current_tab = Tab.GAME_LENGTH


func _on_game_length_menu_finished(wave_count: int):
	_wave_count = wave_count
	_tab_container.current_tab = Tab.DISTRIBUTION


func _on_distribution_menu_finished(distribution: Distribution.enm):
	_distribution = distribution
	_tab_container.current_tab = Tab.DIFFICULTY


func _on_difficulty_menu_finished(difficulty: Difficulty.enm):
	_difficulty = difficulty
	
	finished.emit(_wave_count, _distribution, _difficulty)
