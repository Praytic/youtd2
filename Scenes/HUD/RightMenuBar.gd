extends Control

signal test_signal()

@onready var build_bar = get_node("%BuildBar")
@onready var item_bar = get_node("%ItemBar")


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


func set_element(element: Element.enm):
	if element == Element.enm.NONE:
		item_bar.show()
		build_bar.hide()
	else:
		item_bar.hide()
		build_bar.show()
		build_bar.set_element(element)


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
	set_element(build_bar.get_element())
