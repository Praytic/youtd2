class_name TestTowerVisual
extends Node2D

# TODO: label doesn't work. Visible in editor, invisible ingame.
# Don't know why.

onready var label: Label = $Label


func _ready():
	var tower: Tower = get_parent() as Tower

	if tower != null:
		label.text = tower.get_name()
	else:
		label.text = "Incorrect parent"

