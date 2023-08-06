class_name EmptySlotButton
extends AspectRatioContainer


# Non-functional button used to display an empty slot in
# tower inventory. Note that current implementation
# duplicates the layout of ItemButton and
# UnitButtonContainer. Need to update EmptySlotButton scene
# if the scene for ItemButton changes.


static func make() -> EmptySlotButton:
	return Globals.empty_slot_button_scene.instantiate()
