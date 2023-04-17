extends Node2D


# Corpse visual created after creep dies. Fades away slowly
# then disappears.

const FADE_DURATION: float = 60

@onready var _sprite: Sprite2D = $Sprite2D


func _ready():
# 	Randomize sprite position and scale to make sprites look
# 	varied
	var random_offset: Vector2 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	_sprite.position += random_offset

	var random_scale: Vector2 = Vector2(randf_range(0.95, 1.05), randf_range(0.95, 1.05))
	_sprite.scale *= random_scale

	var fade_tween = create_tween()
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		FADE_DURATION).set_trans(Tween.TRANS_LINEAR)
	fade_tween.finished.connect(on_fade_finished)


func on_fade_finished():
	queue_free()
