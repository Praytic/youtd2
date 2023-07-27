class_name UnitButtonContainer
extends MarginContainer


@onready var _unit_button: UnitButton = $%UnitBtn: set = set_button, get = get_button
@onready var _counter_label: Label = $%CounterLabel
@onready var _counter_container: Label = $%CounterContainer


var _count: int : set = set_count


func set_count(value: int):
	_count = value
	_counter_label.text = str(value)
	if _count > 1:
		_counter_container.show()
	else:
		_counter_container.hide()


func get_button() -> UnitButton:
	return _unit_button


func set_button(value: UnitButton):
	_unit_button = value
