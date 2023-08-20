class_name CreepsProjection extends Node2D


@onready var pos_dict = {}


func _draw():
	for creep_projection_position in pos_dict.values():
		draw_circle(creep_projection_position, 10.0, Color.RED)
