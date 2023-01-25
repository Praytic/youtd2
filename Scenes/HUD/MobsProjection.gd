extends Node2D


onready var pos_dict = {}


func _draw():
	for mob_projection_position in pos_dict.values():
		draw_circle(mob_projection_position, 10.0, Color.red)
