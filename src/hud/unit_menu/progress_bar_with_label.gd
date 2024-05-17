class_name ProgressBarWithLabel extends ProgressBar


# Simple progress bar with label. Need this because the default ProgressBar only allows showing percentage.


@export var _label: Label


func set_text(text: String):
	_label.text = text
