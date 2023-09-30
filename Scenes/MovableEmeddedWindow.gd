extends Window


@export var menu: Control
@export var open_button: BaseButton
@export var start_position: Vector2

func _ready():
	position = Vector2(start_position.x - menu.size.x, start_position.y)
	_on_close_requested()


func _on_close_requested():
	theme_type_variation = "ClosedWindow"
	open_button.show()
	menu.hide()
	max_size = open_button.size
	min_size = open_button.size
	reset_size()
	unresizable = true
	position.x += int(menu.size.x - open_button.size.x)


func _on_open_requested():
	theme_type_variation = ""
	open_button.hide()
	menu.position = Vector2.ZERO
	menu.show()
	max_size = Vector2i(32768, 32768)
	min_size = menu.custom_minimum_size
	reset_size()
	menu.reset_size()
	unresizable = false
	position.x += int(open_button.size.x - menu.size.x)
