extends Node2D

@onready var play_area: CollisionShape2D = $PlayArea/CollisionShape2D

func get_play_area_size() -> Vector2:
	return play_area.get_shape().size

func get_play_area_pos() -> Vector2:
	return play_area.global_position
