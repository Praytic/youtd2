class_name CameraOrigin extends Sprite2D

# Defines an origin for player camera.

@export var player_id: int


func _ready():
	add_to_group("camera_origins")
	
#	NOTE: need to hide camera origin during gameplay. It
#	displays as a sprite in editor, for convenience while
#	developing.
	hide()
