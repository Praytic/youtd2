extends PanelContainer


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.


@export var _label: RichTextLabel

var _current_button: Button = null


func _ready():
	EventBus.tower_button_mouse_entered.connect(_on_tower_button_mouse_entered)
	EventBus.item_button_mouse_entered.connect(_on_item_button_mouse_entered)
	EventBus.research_button_mouse_entered.connect(_on_research_button_mouse_entered)
	EventBus.autocast_button_mouse_entered.connect(_on_autocast_button_mouse_entered)


func _on_tower_button_mouse_entered(tower_id: int, button: Button):
	var text: String = RichTexts.get_tower_text(tower_id)
	_on_generic_button_mouse_entered(button, text)


func _on_item_button_mouse_entered(item: Item, button: Button):
	var text: String = RichTexts.get_item_text(item)
	_on_generic_button_mouse_entered(button, text)


func _on_research_button_mouse_entered(element: Element.enm, button: Button):
	var text: String = RichTexts.get_research_text(element)
	_on_generic_button_mouse_entered(button, text)


func _on_autocast_button_mouse_entered(autocast: Autocast, button: Button):
	var text: String = ""

	text += RichTexts.get_autocast_text(autocast)
	text += " \n"

	if autocast.can_use_auto_mode():
		text += "[color=YELLOW]Right Click to toggle automatic casting on and off[/color]\n"

	text += "[color=YELLOW]Left Click to cast ability[/color]\n"

	_on_generic_button_mouse_entered(button, text)


func _on_generic_button_mouse_entered(button: Button, text: String):
	_clear_current_button()

	_current_button = button
	_current_button.mouse_exited.connect(_clear_current_button)
	_current_button.tree_exiting.connect(_clear_current_button)
	_current_button.hidden.connect(_clear_current_button)

	_label.clear()
	_label.append_text(text)

	show()


func _clear_current_button():
	if _current_button != null && is_instance_valid(_current_button):
		_current_button.mouse_exited.disconnect(_clear_current_button)
		_current_button.tree_exiting.disconnect(_clear_current_button)
		_current_button.hidden.disconnect(_clear_current_button)

	_current_button = null
	hide()
