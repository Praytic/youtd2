class_name CameraOrigin extends Node2D

# Defines an origin for player camera.

@export var player_id: int


func _ready():
	add_to_group("camera_origins")
