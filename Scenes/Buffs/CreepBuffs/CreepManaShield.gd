class_name CreepManaShield extends BuffType


# TODO: what is the formula for "Less mana, less damage reduction."? Made up a placeholder formula for now.

# TODO: how much mana is spend per damage reduction?


func _init(parent: Node):
	super("creep_mana_shield", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var mana_ratio = creep.get_mana_ratio()
	var damage_reduction: float = clampf(1.0 - mana_ratio, 0.2, 1.0)

	event.damage *= damage_reduction

	var mana_before: float = creep.get_mana()
	var mana_after: float = mana_before - 5

	creep.set_mana(mana_after)

	if mana_after <= 0:
#		TODO: explode, leaving no corpse
		pass
