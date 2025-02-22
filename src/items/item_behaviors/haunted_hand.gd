extends ItemBehavior


# NOTE: reworked original script. Used the same logic as in
# "RottedFlashingGrave" tower which also attacks random
# targets.


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.08, 0.002)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.10, 0.01)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var random_unit: Unit = iterator.next_random()

	if random_unit == null:
		return

	tower.issue_target_order(random_unit)
