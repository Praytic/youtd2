class_name CreepMeaty extends BuffType

# TODO: implement dropping food. Figure out how much to drop.

func _init(parent: Node):
	super("creep_meaty", 0, 0, true, parent)

	add_event_on_death(on_death)


func on_death(event: Event):
	var buff: Buff = event.get_buff()
	var unit: Unit = buff.get_buffed_unit()

	var creep: Creep = unit as Creep

	if creep == null:
		return

	var creep_size: CreepSize.enm = creep.get_size()

	if creep_size == CreepSize.enm.CHAMPION || creep_size == CreepSize.enm.BOSS:
#		TODO: Drop food here
		print_verbose("Creep dropped extra food (not implemented).")
