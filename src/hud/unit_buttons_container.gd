class_name UnitButtonsContainer
extends GridContainer


# This GrindContainer will show extra "empty slots" in the
# cells which are not occupied by real buttons. The empty
# slots are implemented by EmptyUnitButton. User of this
# container should add however many EmptyUnitButtons they
# need to be displayed.
# 
# For example, if you set column count to 4 and add 12
# buttons you will get this:
# No real buttons:
# [ ] [ ] [ ] [ ]
# [ ] [ ] [ ] [ ]
# [ ] [ ] [ ] [ ]
# 3 real buttons:
# [x] [x] [x] [ ]
# [ ] [ ] [ ] [ ]
# [ ] [ ] [ ] [ ]
# 5 real buttons:
# [x] [x] [x] [x]
# [x] [ ] [ ] [ ]
# [ ] [ ] [ ] [ ]


var _empty_slots: Array


func _ready():
	_empty_slots = []

#	Collect empty buttons in a list. Note that empty_slots
#	cannot be filled automatically like:
#	@onready var _empty_slots: Array = get_children()
#	Because items may be added to item stash menu before
#	UnitButtonsContainer is ready.
	for button in get_children():
		if button is EmptyUnitButton:
			_empty_slots.append(button)


# Amount of visible empty slots depends on visible unit_buttons 
# inside this container. These unit_buttons should be provided
# by the caller instead of referring to children of the container.
func update_empty_slots(unit_buttons_count: int):
	var rows = ceil((unit_buttons_count * 1.0) / columns)
	
	for empty_slot_idx in range(_empty_slots.size()):
		var current_slot: EmptyUnitButton = _empty_slots[empty_slot_idx]
		var slot_visibility = empty_slot_idx < max(columns * rows, _empty_slots.size()) - unit_buttons_count
		current_slot.visible = slot_visibility
