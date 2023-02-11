extends Button

export(Tower.Element) var element = Tower.Element.ASTRAL


func _pressed():
	emit_signal("pressed", element)
