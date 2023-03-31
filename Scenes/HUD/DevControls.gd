extends Control


@onready var dev_control_buttons = get_tree().get_nodes_in_group("dev_control_button")
@onready var dev_controls = get_tree().get_nodes_in_group("dev_control")


func _ready():
	for dev_control in dev_controls:
		dev_control.close_requested.connect(func (): dev_control.hide())
	
	for dev_control_button in dev_control_buttons:
		dev_control_button.button_up.connect(_on_DevControlButton_button_up.bind(dev_control_button))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_DevControlButton_button_up(button: Button):
	var control_name = button.get_name().replace("Button", "")
	for dev_control in dev_controls:
		if dev_control.get_name() == control_name:
			dev_control.show()
			break
