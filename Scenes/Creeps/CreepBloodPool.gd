extends Node2D


# Corpse visual created after creep dies. Fades away slowly
# then disappears. Note that this is not the corpse.


const FADE_DURATION: float = 60

@export var _sprite: Sprite2D


func _ready():
	var fade_tween = create_tween()
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		FADE_DURATION).set_trans(Tween.TRANS_LINEAR)
	fade_tween.finished.connect(on_fade_finished)


func on_fade_finished():
	queue_free()
