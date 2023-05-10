class_name CreepMagicImmunity extends BuffType

# TODO: this wave special is implemented but I don't
# understand when creep's mana goes below 10. Creeps don't
# spend mana on anything. So these creeps are always immune?
# Doesn't make sense. Couldn't find towers that drain mana
# from creeps.


func _init(parent: Node):
	super("creep_magic_immunity", 0, 0, true, parent)
	add_event_on_damaged(on_damaged, 1.0, 0.0)


func on_damaged(event: Event):
	var creep: Unit = event.get_target()
	var creep_mana: float = Unit.get_unit_state(creep, Unit.State.MANA)
	var has_enough_mana: bool = creep_mana >= 10

	if has_enough_mana && event.is_spell_damage():
		event.damage = 0
