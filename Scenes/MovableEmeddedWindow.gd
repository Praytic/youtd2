extends Window


@export var menu: Control
@export var open_button: BaseButton


func _ready():
	_on_close_requested()


func _on_close_requested():
	theme_type_variation = "ClosedWindow"
	open_button.show()
	menu.hide()
	max_size = open_button.size
	min_size = open_button.size
	reset_size()


func _on_open_requested():
	theme_type_variation = ""
	open_button.hide()
#	reset_size()
	menu.position = Vector2.ZERO
	menu.show()
#	menu.set_anchors_and_offsets_preset(15, 0)
	max_size = Vector2i(32768, 32768)
	min_size = menu.custom_minimum_size
	reset_size()
	menu.reset_size()
