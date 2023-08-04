extends Control


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.


@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel


func _ready():
	EventBus.tower_button_mouse_entered.connect(_on_tower_button_mouse_entered)
	EventBus.tower_button_mouse_exited.connect(_on_tower_button_mouse_exited)
	EventBus.item_button_mouse_entered.connect(_on_item_button_mouse_entered)
	EventBus.item_button_mouse_exited.connect(_on_item_button_mouse_exited)

	EventBus.research_button_mouse_entered.connect(_on_research_button_mouse_entered)
	EventBus.research_button_mouse_exited.connect(_on_research_button_mouse_exited)

	EventBus.autocast_button_mouse_entered.connect(_on_autocast_button_mouse_entered)
	EventBus.autocast_button_mouse_exited.connect(_on_autocast_button_mouse_exited)


func _on_tower_button_mouse_entered(tower_id: int):
	show()

	_label.clear()

	var tower_info_text: String = RichTexts.get_tower_text(tower_id)
	_label.append_text(tower_info_text)


func _on_tower_button_mouse_exited():
	hide()


func _on_item_button_mouse_entered(item: Item):
	show()

	_label.clear()

	var tower_info_text: String = RichTexts.get_item_text(item)
	_label.append_text(tower_info_text)


func _on_item_button_mouse_exited():
	hide()


func _on_research_button_mouse_entered(element: Element.enm):
	show()

	_label.clear()

	var text: String = RichTexts.get_research_text(element)
	_label.append_text(text)


func _on_research_button_mouse_exited():
	hide()


func _on_autocast_button_mouse_entered(autocast: Autocast):
	show()

	_label.clear()

	var text: String = autocast.description
	text = RichTexts.add_color_to_numbers(text)

	text += " \n"
	text += " \n"

	if autocast.can_use_auto_mode():
		text += "[color=YELLOW]Right Click to toggle automatic casting on and off[/color]\n"

	text += "[color=YELLOW]Left Click to cast ability[/color]\n"

	_label.append_text(text)


func _on_autocast_button_mouse_exited():
	hide()
