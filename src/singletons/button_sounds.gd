extends Node


# This class playes a SFX when any button is clicked.

# TODO: fix this to work for title screen as well. Need to
# fix SFX singleton to create audioplayers outside of game
# scene tree. For audioplayers without position that's okay.


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node:Node) -> void:
	if node is Button:
		node.pressed.connect(_on_button_pressed)


# TODO: decide on a good SFX
func _on_button_pressed() -> void:
	return
	# SFX.play_sfx(SfxPaths.PRESS_BUTTON, 0, randf_range(0.9, 1.1))
