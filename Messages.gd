extends Node

# Functions that display messages to the player.


@onready var _error_message_label: ErrorMessageLabel = get_tree().get_root().get_node("GameScene").get_node("UI").get_node("HUD").get_node("ErrorMessageLabel")


func add_error(text: String):
	_error_message_label.add(text)
