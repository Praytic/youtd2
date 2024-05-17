extends Control


@export var livesBar: TextureProgressBar


func _process(_delta: float):
#	TODO: implement setter for lives and call it.
#	Currently top left menu is not used.
	var portal_lives_string: String = "placeholder (todo)"
	livesBar.value = 11
	livesBar.tooltip_text = "Lives left: %s" % portal_lives_string
