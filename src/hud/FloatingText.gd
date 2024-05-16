class_name FloatingText extends Node2D


const SEC_TO_MSEC: float = 1000


@export var label: Label

# NOTE: customize these values before calling adding
# floating text to scene
var text: String = "placeholder"
# The amount of time in seconds, after which floating text disappears
var duration: float = 4.0
# The amount of time in seconds, after which floating text starts fading
var fadepoint: float = 2.0
# NOTE: velocity is in pixels/ms
var velocity: Vector2 = Vector2(0, -0.05)
var color: Color = Color.WHITE
# This random offset is applied to the initial position of
# the floating text, both x and y coordinates.
var random_offset: float = 0.0


#########################
###     Built-in      ###
#########################

func _ready():
	label.text = text
	modulate = color

	position += Vector2(Globals.local_rng.randf_range(-random_offset, random_offset), Globals.local_rng.randf_range(-random_offset, random_offset))

# 	Text bounces up and right
	var pos_tween = create_tween()
	var duration_msec: float = duration * SEC_TO_MSEC
	var offset: Vector2 = velocity * duration_msec
	pos_tween.tween_property(self, "position",
		position + offset,
		1.0 * duration).set_trans(Tween.TRANS_LINEAR)

# 	Text fades away to nothing at the end
	if fadepoint < duration:
		var modulate_tween = create_tween()
		var fade_duration: float = duration - fadepoint
		modulate_tween.tween_property(self, "modulate",
			Color(modulate.r, modulate.g, modulate.b, 0),
			fade_duration).set_trans(Tween.TRANS_LINEAR).set_delay(fadepoint)

	var queue_free_tween = create_tween()
	queue_free_tween.tween_callback(queue_free).set_delay(duration)
