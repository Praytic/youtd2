extends Button


export(String) var element


func _pressed():
	emit_signal("pressed", element)
