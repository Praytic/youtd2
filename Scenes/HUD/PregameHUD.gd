extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


signal selected_difficulty(difficulty: Difficulty.enm)


func _on_generic_button_pressed(difficulty: Difficulty.enm):
	selected_difficulty.emit(difficulty)


func _on_beginner_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.BEGINNER)


func _on_easy_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.EASY)


func _on_medium_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.MEDIUM)


func _on_hard_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.HARD)


func _on_extreme_button_pressed():
	_on_generic_button_pressed(Difficulty.enm.EXTREME)
