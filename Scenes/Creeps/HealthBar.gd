@tool
extends ProgressBar


@export var _health_style_box: StyleBoxFlat
@export var color3: Color
@export var color2: Color
@export var color1: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	remove_theme_stylebox_override("Fill")
	add_theme_stylebox_override("Fill", _health_style_box)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var health_left = value / max_value
	if health_left > 0.75:
		_health_style_box.bg_color = color3
	elif health_left > 0.5:
		_health_style_box.bg_color = lerp(color2, color3, (value / max_value - 0.5) * 4)
	elif health_left > 0.25:
		_health_style_box.bg_color = lerp(color1, color2, (value / max_value - 0.25) * 4)
	else:
		_health_style_box.bg_color = color1

