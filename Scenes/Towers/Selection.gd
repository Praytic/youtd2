extends Node2D


func _draw():
	draw_set_transform_matrix(Transform2D.scaled(Vector2(1, 0.5)))
	draw_arc(Vector2.ZERO, get_parent().cell_size, deg2rad(0), deg2rad(360), 100, Color.white, 1.5, true)
