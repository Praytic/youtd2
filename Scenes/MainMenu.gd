extends Node

# Main menu for the game. Opens when the game starts.


func _on_button_pressed():
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)


func _on_quit_button_pressed():
	get_tree().quit()
