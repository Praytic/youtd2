class_name ElementsContainer extends VBoxContainer


signal element_changed()


var _current_element: Element.enm = Element.enm.ICE : get = get_element


#########################
###     Built-in      ###
#########################

func _ready():
	HighlightUI.register_target("elements_container", self)
	self.element_changed.connect(func(): HighlightUI.highlight_target_ack.emit("elements_container"))


#########################
###       Public      ###
#########################

func get_element() -> Element.enm:
	return _current_element


func set_player(player: Player):
	for button in get_children():
		button.set_player(player)


#########################
###     Callbacks     ###
#########################

func _on_element_button_pressed(element: Element.enm):
	_current_element = element
	element_changed.emit()
