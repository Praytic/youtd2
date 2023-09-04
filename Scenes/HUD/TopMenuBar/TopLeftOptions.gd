extends Control


@export var livesBar: TextureProgressBar


func _process(_delta: float):
	var portal_lives: float = PortalLives.get_current()
	var portal_lives_string: String = PortalLives.get_lives_string()
	livesBar.value = max(portal_lives, 0)
	livesBar.tooltip_text = "Lives left: %s" % portal_lives_string
