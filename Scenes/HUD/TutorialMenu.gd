class_name TutorialMenu extends PanelContainer


# Tutorial menu displays a tutorial. Controlled by TutorialController.


signal player_pressed_next()
signal player_pressed_back()
signal player_pressed_close()


@export var _text_label: RichTextLabel
@export var _back_button: Button
@export var _next_button: Button


#########################
###       Public      ###
#########################

func set_text(text: String):
	_text_label.clear()
	_text_label.append_text(text)


func set_next_disabled(value: bool):
	_next_button.disabled = value


func set_back_disabled(value: bool):
	_back_button.disabled = value


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed():
	player_pressed_close.emit()


func _on_next_button_pressed():
	player_pressed_next.emit()


func _on_back_button_pressed():
	player_pressed_back.emit()
