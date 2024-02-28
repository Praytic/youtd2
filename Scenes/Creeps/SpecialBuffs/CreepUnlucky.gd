class_name CreepUnlucky extends BuffType


var unlucky_active: BuffType


func _init(parent: Node):
	super("creep_unlucky", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)

	unlucky_active = BuffType.new("unlucky_active", 8.0, 0, false, self
		)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, -0.001)
	unlucky_active.set_buff_modifier(modifier)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()

	if !creep.calc_chance(0.30):
		return

	var active_buff: Buff = attacker.get_buff_of_type(unlucky_active)

	if active_buff != null:
		active_buff = unlucky_active.apply(creep, attacker, active_buff.get_level() + 10)
		active_buff.refresh_duration()
	else:
		active_buff = unlucky_active.apply(creep, attacker, 10)
