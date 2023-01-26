extends Control

func _ready():
	self.hide()


func _on_Button_pressed():
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_accept"):
		hide()
