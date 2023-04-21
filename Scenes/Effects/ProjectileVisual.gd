extends Sprite2D


# Rotate projectile so it looks more dynamic
func _process(delta):
	rotate(20.0 * delta)
