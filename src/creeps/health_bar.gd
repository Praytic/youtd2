@tool
extends ProgressBar


# The health bar changes colors based on current health.
# Green at full health, orange at middle, red when close to
# 0%.

@export var color3: Color
@export var color2: Color
@export var color1: Color


# NOTE: load color for initial value here
func _ready():
	_on_value_changed(value)

# Divides two floats. In case of division by 0, returns
# "result_when_divide_by_zero" arg, 0 by default.
# NOTE: this function must be used instead of "/" whenever
# there's division by variable which has any chance of
# being 0.
func divide_safe_tool(a: float, b: float, result_when_divide_by_zero: float = 0.0) -> float:
	if b != 0.0:
		var ratio: float = a / b

		return ratio
	else:
		return result_when_divide_by_zero

func _on_value_changed(new_value: float):
	var health_ratio: float = divide_safe_tool(new_value, max_value)

	var current_color: Color
	if health_ratio > 0.75:
		current_color = color3
	elif health_ratio > 0.5:
		current_color = lerp(color2, color3, (health_ratio - 0.5) * 4)
	elif health_ratio > 0.25:
		current_color = lerp(color1, color2, (health_ratio - 0.25) * 4)
	else:
		current_color = color1

	modulate = current_color
