class_name TutorialMenu extends PanelContainer


@export var _text_label: RichTextLabel
@export var _display_tutorial_check_box: CheckBox


var _tutorial_id: int = -1


#########################
###       Public      ###
#########################

func set_tutorial_id(tutorial_id: int):
	_tutorial_id = tutorial_id

	var tutorial_title: String = TutorialProperties.get_title(tutorial_id)
	var tutorial_text: String = TutorialProperties.get_text(tutorial_id)
	var text: String = "[color=GOLD]%s[/color]\n \n%s" % [tutorial_title, tutorial_text]
	
	_text_label.clear()
	_text_label.append_text(text)


#########################
###     Callbacks     ###
#########################

func _on_okay_button_pressed():
	var display_tutorial_checkbox_is_checked: bool = _display_tutorial_check_box.is_pressed()
	if !display_tutorial_checkbox_is_checked:
		Settings.set_setting(Settings.SHOW_TUTORIAL_ON_START, false)
		Settings.flush()

	hide()

	EventBus.finished_tutorial_section.emit()
