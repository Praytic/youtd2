class_name CreepManaShieldPlus extends BuffType


# TODO: what is the formula for "Less mana, less damage reduction."? Made up a placeholder formula for now.

# TODO: how much mana is spend per damage reduction?

# TODO: what's the difference between mana shield and mana
# shield plus? For now, made plus version give more damage
# reduction.


func _init(parent: Node):
	super("creep_mana_shield_plus", 0, 0, true, parent)

	add_event_on_damaged(on_damaged)


func on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var mana_ratio = creep.get_mana_ratio()
	var damage_reduction: float = min(0.8, mana_ratio * 2)

	event.damage *= damage_reduction

	var mana_before: float = Unit.get_unit_state(creep, Unit.State.MANA)
	var mana_after: float = mana_before - 5

	Unit.set_unit_state(creep, Unit.State.MANA, mana_after)

	if mana_after <= 0:
#		TODO: explode, leaving no corpse
		pass
