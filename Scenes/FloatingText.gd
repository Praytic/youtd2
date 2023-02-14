extends Node2D


onready var tween: Tween = $Tween
onready var label: Label = $Label

var text: String = "placeholder"
var duration: float = 1.0
var color: Color = Color.white


func _ready():
	label.text = text
	modulate = color

# 	Text pops out at the start
	tween.interpolate_property(self, "scale",
		Vector2(0, 0),
		Vector2(1.0, 1.0),
		0.3 * duration, Tween.TRANS_QUART, Tween.EASE_OUT)

# 	Text fades to transparent after popping out
	tween.interpolate_property(self, "modulate",
		color,
		Color(color.r, color.g, color.b, 0),
		0.3 * duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.7 * duration)

# 	Text shrinks while fading
	tween.interpolate_property(self, "scale",
		Vector2(1.0, 1.0),
		Vector2(0.4, 0.4),
		1.0 * duration, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.6 * duration)

# 	Text bounces
	tween.interpolate_property(self, "position",
		Vector2(0, 0),
		Vector2(50, -50),
		1.0 * duration, Tween.TRANS_SINE, Tween.EASE_OUT)

	tween.interpolate_callback(self, 1.0 * duration, "queue_free")

	tween.start()
