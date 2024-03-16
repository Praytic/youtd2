class_name EmptyUnitButton
extends Button


static func make() -> EmptyUnitButton:
	var button: EmptyUnitButton = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn").instantiate()

	return button
