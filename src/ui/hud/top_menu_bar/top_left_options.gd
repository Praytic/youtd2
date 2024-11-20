extends Control


# NOTE: this file is unused

@export var livesBar: TextureProgressBar


func _process(_delta: float):
	var portal_lives_string: String = "placeholder (todo)"
	livesBar.value = 11
	livesBar.tooltip_text = "Lives left: %s" % portal_lives_string
