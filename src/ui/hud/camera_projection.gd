class_name CameraProjection extends Node2D


# NOTE: this file is unused


var _camera_projection_size: Vector2

func _draw():
	var camera_projection_rect = Rect2(Vector2.ZERO, _camera_projection_size)
	draw_rect(camera_projection_rect, Color.WHITE, false)

func set_size(value: Vector2):
	_camera_projection_size = value
