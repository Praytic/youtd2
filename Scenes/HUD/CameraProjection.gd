extends Node2D

func _draw():
	draw_circle(global_position, 100.0, Color.white)
	print("Circle: %s" % position)
