class_name UnitButtonContainer
extends MarginContainer


@onready var _counter_label: Label = $%CounterLabel
@onready var _counter_container: Label = $%CounterContainer
@onready var _unit_button_container: Container = $%UnitButtonContainer


var _count: int : set = set_count


func set_count(value: int):
	_count = value
	_counter_label.text = str(value)
	if _count > 1:
		_counter_container.show()
	else:
		_counter_container.hide()


func get_button() -> UnitButton:
	return _unit_button_container.get_child(0)


func set_button(value: UnitButton):
	_unit_button_container.remove_child(get_button())
	_unit_button_container.add_child(value)
