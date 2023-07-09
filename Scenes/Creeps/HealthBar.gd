@tool
extends ProgressBar

@export var color3: Color
@export var color2: Color
@export var color1: Color


func _on_value_changed(new_value: float):
	var health_left = new_value / max_value
	if health_left > 0.75:
		get_theme_stylebox("fill").bg_color = color3
	elif health_left > 0.5:
		get_theme_stylebox("fill").bg_color = lerp(color2, color3, (new_value / max_value - 0.5) * 4)
	elif health_left > 0.25:
		get_theme_stylebox("fill").bg_color = lerp(color1, color2, (new_value / max_value - 0.25) * 4)
	else:
		get_theme_stylebox("fill").bg_color = color1
