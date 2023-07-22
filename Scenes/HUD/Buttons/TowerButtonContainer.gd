extends Control


@export var _counter_label: Label
@export var _count: int:
	set(value):
		_update_counter(value)
	get:
		return _count


func _update_counter(value: int):
	if value > 0:
		_counter_label.show()
	else:
		_counter_label.hide()
	_counter_label.text = str(value)
	_count = value
