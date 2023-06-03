class_name CreepStunRevenge extends BuffType


var cb_stun: BuffType


func _init(parent: Node):
	super("creep_stun_revenge", 0, 0, true, parent)

	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()
	var stun_success: bool = creep.calc_chance(0.3)

	if stun_success:
		cb_stun.apply_only_timed(creep, attacker, 3.0)
