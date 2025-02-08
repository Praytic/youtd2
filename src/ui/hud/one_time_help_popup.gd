class_name OneTimeHelpPopup extends PanelContainer


# This is a one time popup which is shown when player starts
# up the game for the first time. It tells the player the
# basics about how to pause the game and that there's a Help
# menu. It's need to make sure that players learn about
# Pause and Help menu (even though the Tutorial also teaches
# about this).


signal close_pressed()


func _on_close_button_pressed() -> void:
	close_pressed.emit()
