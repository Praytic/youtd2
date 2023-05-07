class_name CreepInvisible extends BuffType


func _init(parent: Node):
	super("creep_invisible", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_HP_PERC, -0.075, 0.0)
	set_buff_modifier(modifier)
	set_buff_tooltip("Invisible\nYour builder and some towers are able to see invisible units.")

	add_event_on_create(on_create)


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.set_invisible(true)
