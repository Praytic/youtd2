extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_DevControlButton_button_down():
	var dev_controls = get_tree().get_nodes_in_group("dev_control")
	for dev_control in dev_controls:
		dev_control.hide()
