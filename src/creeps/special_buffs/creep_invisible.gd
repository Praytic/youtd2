class_name CreepInvisible extends BuffType


# NOTE: this is commented out because invisibility mechanic
# is not implemented


func _init(parent: Node):
	super("creep_invisible", 0, 0, true, parent)

	# add_event_on_create(on_create)


# func on_create(event: Event):
# 	var buff: Buff = event.get_buff()
# 	var creep: Unit = buff.get_buffed_unit()
# 	creep.set_invisible(true)
