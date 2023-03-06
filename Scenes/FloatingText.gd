extends Node2D


# TODO: update to new tween API

@onready var label: Label = $Label
var text: String = "placeholder"
var duration: float = 1.0
var color: Color = Color.WHITE

func _ready():
	label.text = text
	modulate = color

# 	Text bounces up and right
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position",
		Vector2(50, -50),
		1.0 * duration).set_trans(Tween.TRANS_SINE)

# 	Text pops out of nothing then shrinks
	var scale_tween = create_tween()
	scale = Vector2(0, 0)
	scale_tween.tween_property(self, "scale",
		Vector2(1.0, 1.0),
		0.3 * duration).set_trans(Tween.TRANS_QUART)
	scale_tween.tween_property(self, "scale",
		Vector2(0.4, 0.4),
		0.7 * duration).set_trans(Tween.TRANS_LINEAR)

# 	Text fades away to nothing at the end
	var modulate_tween = create_tween()
	modulate_tween.tween_property(self, "modulate",
		Color(modulate.r, modulate.g, modulate.b, 0),
		0.3 * duration).set_trans(Tween.TRANS_LINEAR).set_delay(0.7 * duration)

	var queue_free_tween = create_tween()
	queue_free_tween.tween_callback(queue_free).set_delay(1.0)
