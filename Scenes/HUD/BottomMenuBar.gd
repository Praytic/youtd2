class_name BottomMenuBar extends Control


signal research_element()
signal test_signal()

@export var _item_bar: GridContainer
@export var _build_bar: GridContainer
@export var _item_menu_button: Button
@export var _building_menu_button: Button
@export var _research_panel: Control


func _ready():
#	NOTE: on html5 build created on github CI, connections
#	for some reason don't work when a signal from parent is
#	connected to slot in child. Leave this in for debug
#	purposes.
	var connection_count: int = test_signal.get_connections().size()
	print_verbose("-----\nRightMenuBar connection_count = %d" %connection_count)
	if connection_count == 0:
		print_verbose("!!!!!\nconnection bug still exists\n!!!!!!")
	
	for element_button in get_element_buttons():
		element_button.pressed.connect(_on_ElementButton_pressed.bind(element_button))


func _process(_delta):
	var item_button_count: int = _item_bar.get_item_count()
	_item_menu_button.text = str(item_button_count)
	
	_building_menu_button.text = str(_build_bar.get_child_count())


func get_item_menu_button() -> Button:
	return _item_menu_button


func set_element(element: Element.enm):
	if element == Element.enm.NONE:
		_item_bar.show()
		_build_bar.hide()
	else:
		_item_bar.hide()
		_build_bar.show()
		_build_bar.set_element(element)


# NOTE: have to manually call this because ItemMovement
# can't detect clicks on right menu bar.
func _gui_input(event):
	if event.is_action_released("left_click"):
		ItemMovement.on_clicked_on_right_menu_bar()

func get_element_buttons() -> Array:
	return get_tree().get_nodes_in_group("element_button")


func _on_ItemMenuButton_pressed():
	set_element(Element.enm.NONE)


func _on_ElementButton_pressed(element_button):
	set_element(element_button.element)


func _on_BuildMenuButton_pressed():
	set_element(_build_bar.get_element())


func _on_research_button_pressed():
	_research_panel.visible = !_research_panel.visible
