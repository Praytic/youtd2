class_name ButtonStatusCard
extends PanelContainer


@export var _main_button: Button


@onready var _hidable_status_panels: Array = get_tree().get_nodes_in_group("hidable_status_panel")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
