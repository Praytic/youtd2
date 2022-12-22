extends Control

onready var camera: Camera2D = get_node(@"/root/GameScene/DefaultCamera")

func _unhandled_input(event):
	CameraManager.zoom()
