extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	text = Config.build_version()
