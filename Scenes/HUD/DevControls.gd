extends Control


@onready var dev_control_buttons = get_tree().get_nodes_in_group("dev_control_button")
@onready var dev_controls = get_tree().get_nodes_in_group("dev_control")
@onready var positional_control: PopupMenu = $PositionalControl


func _ready():
	for dev_control in dev_controls:
		dev_control.close_requested.connect(func (): dev_control.hide())
	
	for dev_control_button in dev_control_buttons:
		dev_control_button.button_up.connect(_on_DevControlButton_button_up.bind(dev_control_button))
	
	# TODO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _unhandled_input(event):
	if event is InputEventMouse:
		var right_click: bool = event.is_action_released("right_click")
		if right_click:
			positional_control.show()
			positional_control.position = event.position
		else:
			positional_control.hide()

func _on_DevControlButton_button_up(button: Button):
	var control_name = button.get_name().replace("Button", "")
	for dev_control in dev_controls:
		if dev_control.get_name() == control_name:
			dev_control.show()
			break

func _on_PositionalControl_id_focused(id):
	match id:
		0: print_verbose("TODO")
		_: push_error("Invalid index for positional control: %s" % id)

