class_name ProgressBarWithLabel extends ProgressBar


# Simple progress bar with label. Need this because the default ProgressBar only allows showing percentage.


@export var _label: Label


func set_text(text: String):
	_label.text = text


# This function makes sure that the text will fit into the
# width of the progress bar
func set_ratio_custom(left: int, right: int):
	var left_string: String = TowerDetails.int_format_shortest(left)
	var right_string: String = TowerDetails.int_format_shortest(right)
	var text: String = "%s/%s" % [left_string, right_string]
	set_text(text)

	var value_ratio: float = Utils.divide_safe(left, right)
	value_ratio = clampf(value_ratio, 0.0, 1.0)
	set_as_ratio(value_ratio)
