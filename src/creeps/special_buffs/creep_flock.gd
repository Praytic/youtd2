class_name CreepFlock extends BuffType


func _init(parent: Node):
	super("creep_flock", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_BOUNTY_GRANTED, -0.50, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_EXP_GRANTED, -0.50, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH, -0.50, 0.0)
	set_buff_modifier(modifier)

	add_event_on_create(on_create)


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()

	creep.set_portal_damage_multiplier(0.5)

