class_name CreepPurgeRevenge extends BuffType


var slow_attack: BuffType


func _init(parent: Node):
	super("creep_purge_revenge", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	slow_attack = BuffType.new("creep_slow_attack", 4.0, 0.0, false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -1.5, 0.0)
	slow_attack.set_buff_modifier(modifier)
	slow_attack.set_buff_tooltip("Revenge\nThis unit is afflicted by Revenge; it has reduced attack speed.")


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()

	if !creep.calc_chance(0.15):
		return

	for i in range(0, 2):
		attacker.purge_buff(true)
		slow_attack.apply(creep, attacker, 1)
