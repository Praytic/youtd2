class_name ElementButton extends Button


# This button is used in Elements menu.


@export var _level_label: Label


func set_level(level: int):
	_level_label.text = str(level)
