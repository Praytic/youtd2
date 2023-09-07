class_name CreepMagicImmunity extends BuffType


func _init(parent: Node):
	super("creep_magic_immunity", 0, 0, true, parent)
	add_periodic_event(periodic, 0.1)


func periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var creep_mana: float = creep.get_mana()
	var should_be_immune: bool = creep_mana >= 10
	creep.set_immune(should_be_immune)
