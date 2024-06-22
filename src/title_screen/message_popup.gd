class_name MessagePopup extends PopupPanel


# Popup for displaying messages in title screen.


var _text: String = ""

@export var _label: Label


#########################
###     Built-in      ###
#########################

func _ready():
	_label.text = _text


#########################
###       Static      ###
#########################

static func make(text: String) -> MessagePopup:
	var scene: PackedScene = load("res://src/title_screen/message_popup.tscn")
	var instance: MessagePopup = scene.instantiate()
	instance._text = text
	
	return instance


#########################
###     Callbacks     ###
#########################

func _on_ok_button_pressed():
	hide()
	queue_free()
