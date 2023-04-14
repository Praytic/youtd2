extends Control

signal test_signal()

@onready var builder_control = get_tree().current_scene.get_node("%BuilderControl")
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var build_bar = get_node("%BuildBar")
@onready var item_bar = get_node("%ItemBar")


func _ready():
	self.hide()
	builder_control.tower_built.connect(_on_UnitButton_pressed)
	item_control.item_used.connect(_on_UnitButton_pressed)

#	NOTE: on html5 build created on github CI, connections
#	for some reason don't work when a signal from parent is
#	connected to slot in child. Leave this in for debug
#	purposes.
	var connection_count: int = test_signal.get_connections().size()
	Utils.log_debug("-----\nRightMenuBar connection_count = %d" %connection_count)
	if connection_count == 0:
		Utils.log_debug("!!!!!\nconnection bug still exists\n!!!!!!")


func set_element(element: Tower.Element):
	show()

	if element == Tower.Element.NONE:
		item_bar.show()
		item_bar.adjust_size()
		build_bar.hide()
	else:
		item_bar.hide()
		build_bar.show()
		build_bar.set_element(element)


func _unhandled_input(event):
	var move_in_progress: bool = ItemMovement.item_move_in_progress()

	if event.is_action_released("ui_cancel") && ! move_in_progress:
		hide()


func _on_UnitButton_pressed(_unit_id):
	pass
