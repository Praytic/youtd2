class_name UnitButtonsContainer
extends GridContainer


# GridContainer which uses this script should have
# all empty slots added to the node before it is ready.
@onready var _empty_slots: Array = get_children()


# Amount of visible empty slots depends on visible unit_buttons 
# inside this container. These unit_buttons should be provided
# by the caller instead of referring to children of the container.
func update_empty_slots(unit_buttons_count: int):
	var rows = ceil((unit_buttons_count * 1.0) / columns)
	
	for empty_slot_idx in range(_empty_slots.size()):
		var current_slot: EmptyUnitButton = _empty_slots[empty_slot_idx]
		var slot_visibility = empty_slot_idx < max(columns * rows, _empty_slots.size()) - unit_buttons_count
		current_slot.visible = slot_visibility
