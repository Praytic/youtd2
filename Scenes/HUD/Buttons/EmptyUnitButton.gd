class_name EmptyUnitButton
extends Button


static func make() -> EmptyUnitButton:
	return Globals.empty_slot_button_scene.instantiate()
