class_name CreepEvasion extends BuffType


func _init(parent: Node):
	super("creep_evasion", 0, 0, true, parent)
	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	CreepEvasion.evasion_effect(event, 0.25)


static func evasion_effect(event: Event, chance: float):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var tower: Unit = event.get_target()
	var evade_success: bool = creep.calc_chance(chance)

	if evade_success:
		event.damage = 0
		tower.get_player().display_floating_text_x("Miss", tower, 255, 0, 0, 255, 0.05, 0.0, 2.0)
