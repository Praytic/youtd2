class_name EmptyUnitButton
extends Button


static func make() -> EmptySlotButton:
	return Globals.empty_slot_button_scene.instantiate()
