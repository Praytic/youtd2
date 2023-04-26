extends Control

signal test_signal()

@onready var build_bar = get_node("%BuildBar")
@onready var item_bar = get_node("%ItemBar")


func _ready():
	self.hide()

#	NOTE: on html5 build created on github CI, connections
#	for some reason don't work when a signal from parent is
#	connected to slot in child. Leave this in for debug
#	purposes.
	var connection_count: int = test_signal.get_connections().size()
	print_verbose("-----\nRightMenuBar connection_count = %d" %connection_count)
	if connection_count == 0:
		print_verbose("!!!!!\nconnection bug still exists\n!!!!!!")


func set_element(element: Tower.Element):
	show()

	if element == Tower.Element.NONE:
		item_bar.show()
		build_bar.hide()
	else:
		item_bar.hide()
		build_bar.show()
		build_bar.set_element(element)


# NOTE: have to manually call this because ItemMovement
# can't detect clicks on right menu bar.
func _gui_input(event):
	if event.is_action_pressed("left_click"):
		ItemMovement.on_clicked_on_right_menu_bar()


func _unhandled_input(event):
	var move_in_progress: bool = ItemMovement.item_move_in_progress()
	var build_in_progress: bool = BuildTower.build_tower_in_progress()

	if event.is_action_released("ui_cancel") && !move_in_progress && !build_in_progress:
		hide()
