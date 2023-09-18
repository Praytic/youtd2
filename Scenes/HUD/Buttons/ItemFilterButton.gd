class_name ItemFilterButton
extends Button


@export var _items_count: Label


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_items_count(value: int):
	if value == 0:
		_items_count.text = ""
	else:
		_items_count.text = str(value)


func _on_mouse_entered():
	_items_count.show()


func _on_mouse_exited():
	_items_count.hide()
