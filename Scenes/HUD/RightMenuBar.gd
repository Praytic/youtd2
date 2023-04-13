extends Control


signal element_changed(element)


@onready var builder_control = get_tree().current_scene.get_node("%BuilderControl")
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var build_bar = get_node("%BuildBar")
@onready var item_bar = get_node("%ItemBar")


func _ready():
	self.hide()
	builder_control.tower_built.connect(_on_UnitButton_pressed)
	item_control.item_used.connect(_on_UnitButton_pressed)

	print("\n\nready, element_changed connections=", element_changed.get_connections())


func set_element(element: Tower.Element):
	print_debug("set_element=%d" % element)
	print_debug("emit signal")
	element_changed.emit(element)
	print_debug("manually call slot")
	build_bar._on_RightMenuBar_element_changed(element)
	show()
	if element == Tower.Element.NONE:
		item_bar.show()
		build_bar.hide()
	else:
		item_bar.hide()
		build_bar.show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		hide()


func _on_UnitButton_pressed(_unit_id):
	pass
