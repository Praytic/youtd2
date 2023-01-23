extends HBoxContainer


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")


func _ready():
	var buttons = get_children()
	for button in buttons:
		button.connect("pressed", builder_control, "on_build_button_pressed", [button.tower_id])
