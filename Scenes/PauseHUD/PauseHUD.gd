extends Control


signal resume_pressed()


func _on_resume_button_pressed():
	resume_pressed.emit()
