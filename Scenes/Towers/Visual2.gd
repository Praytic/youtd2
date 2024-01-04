@tool
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$SelectionOutline.position = $Sprite2D.position
	$SelectionOutline.scale = $Sprite2D.scale
