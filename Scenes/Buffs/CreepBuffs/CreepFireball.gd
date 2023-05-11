class_name CreepFireball extends BuffType


func _init(parent: Node):
	super("creep_fireball", 0, 0, true, parent)

	add_event_on_damaged(on_damaged, 0.05, 0.0)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()

	creep.kill_instantly(attacker)
