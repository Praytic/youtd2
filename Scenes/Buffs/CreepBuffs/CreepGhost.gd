class_name CreepGhost extends BuffType


func _init(parent: Node):
	super("creep_ghost", 0, 0, true, parent)
	add_event_on_damaged(on_damaged, 1.0, 0.0)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var ignore_attack_damage: bool = creep.calc_chance(0.90)

	if ignore_attack_damage && !event.is_spell_damage():
		event.damage = 0
