class_name CreepXtremeEvasion extends BuffType


func _init(parent: Node):
	super("creep_xtreme_evasion", 0, 0, true, parent)
	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var evade_success: bool = creep.calc_chance(0.66)

	if evade_success:
		event.damage = 0
