extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	play("default")


func _on_AnimatedSprite_animation_finished():
	queue_free()
