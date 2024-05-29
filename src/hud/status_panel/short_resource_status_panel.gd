class_name ShortResourceStatusPanel
extends MarginContainer


# NOTE: this file is unused


@export var _resource_count_label: Label
@export var _new_resource_count_label: Label


var _count: int : set = set_count
var _unchecked_count: int


func _process(_delta: float):
	_resource_count_label.text = str(min(_count, 999))
	if _unchecked_count > 0:
		_new_resource_count_label.text = "(+%s)" % str(min(_unchecked_count, 99))
	else:
		_new_resource_count_label.text = ""


func set_count(value: int):
	_unchecked_count += max(0, value - _count)
	_count = value


func ack_count():
	_unchecked_count = 0
