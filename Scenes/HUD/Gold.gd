@tool
extends "res://Scenes/HUD/ResourceStatusPanel.gd"


@onready var gold_control = get_tree().current_scene.get_node("%GoldControl")


func _ready():
	super()

	gold_control.gold_change.connect(_on_gold_change)

	var initial_value: int = int(gold_control.get_gold())
	_on_gold_change(initial_value)


func _on_gold_change(new_value):
	set_label_text(str(int(new_value)))
