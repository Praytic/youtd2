class_name CreepStunRevenge extends BuffType


var stun_bt: BuffType


func _init(parent: Node):
	super("creep_stun_revenge", 0, 0, true, parent)

	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	add_event_on_attacked(on_attacked)


func on_attacked(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()
	var stun_success: bool = creep.calc_chance(0.3)

	if stun_success:
		stun_bt.apply_only_timed(creep, attacker, 3.0)
