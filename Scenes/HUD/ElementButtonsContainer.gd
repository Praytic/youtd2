extends MarginContainer



func _ready():
	hide()


func _on_BuildingMenuButton_pressed():
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		hide()
