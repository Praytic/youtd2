extends Node2D


func _draw():
	if get_parent().get_selection_size():
		draw_set_transform_matrix(Transform2D.scaled(Vector2(1, 0.5)))
		draw_arc(Vector2.ZERO, get_parent().get_selection_size(), deg_to_rad(0), deg_to_rad(360), 100, Color.WHITE, 1.5, true)
