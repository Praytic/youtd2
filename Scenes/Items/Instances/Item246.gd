# Haunted Hand
extends Item


# NOTE: reworked original script. Used the same logic as in
# "RottedFlashingGrave" tower which also attacks random
# targets.


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Haunted![/color]\n"
	text += "This item makes its carrier attack random targets.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.08, 0.002)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack, 1.0, 0.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.10, 0.01)


func on_attack(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 2000)
	var random_unit: Unit = iterator.next_random()

	tower.issue_target_order("attack", random_unit)
