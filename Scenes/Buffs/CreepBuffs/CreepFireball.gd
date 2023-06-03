class_name CreepFireball extends BuffType


func _init(parent: Node):
	super("creep_fireball", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()

	if !creep.calc_chance(0.05):
		return

	creep.kill_instantly(attacker)
