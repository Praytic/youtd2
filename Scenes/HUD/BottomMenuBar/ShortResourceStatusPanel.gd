class_name ShortResourceStatusPanel
extends MarginContainer


@export var _resource_count_label: Label
@export var _new_resource_count_label: Label


var count_tracker: Utils.ValueTracker


func _process(delta):
	_resource_count_label.text = str(count_tracker.get_value())
	_new_resource_count_label.text = str(count_tracker.get_value_change())
