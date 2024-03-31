class_name QuitMenu extends VBoxContainer

signal go_to_title_pressed()
signal quit_game_pressed()
signal cancel_pressed()


func _on_go_to_title_button_pressed():
	go_to_title_pressed.emit()


func _on_quit_game_button_pressed():
	quit_game_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()