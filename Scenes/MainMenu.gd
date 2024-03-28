extends Node


func _on_button_pressed():
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)
