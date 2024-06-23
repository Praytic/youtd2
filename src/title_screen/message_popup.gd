class_name MessagePopup extends PopupPanel


# Popup for displaying messages in title screen.


var _text: String = ""

@export var _label: RichTextLabel


#########################
###     Built-in      ###
#########################

func _ready():
	_label.clear()
	_label.append_text(_text)
	
#	NOTE: autowrap mode of RichTextLabel must be set to
#	"Word" in the scene. Otherwise, RichTextLabel behaves
#	weirdly by expanding to maximum available height. This
#	makes the popup very tall.
	var autowrap_mode_is_correct: bool = _label.autowrap_mode == TextServer.AutowrapMode.AUTOWRAP_WORD
	if !autowrap_mode_is_correct:
		push_error("RichTextLabel autowrap mode is incorrect. Make sure it's set to Word in the scene.")


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
