extends AnimatedSprite2D


# A bouncing arrow pointing down. Used to indicate a
# targeted creep.


const BOUNCE_TIME: float = 0.3
const BOUNCE_HEIGHT: float = 30.0


func _ready():
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "offset",
		offset - Vector2(0, BOUNCE_HEIGHT),
		BOUNCE_TIME).set_ease(Tween.EASE_IN)
	pos_tween.tween_property(self, "offset",
		offset,
		BOUNCE_TIME).set_delay(BOUNCE_TIME).set_ease(Tween.EASE_IN)
	pos_tween.set_loops()
