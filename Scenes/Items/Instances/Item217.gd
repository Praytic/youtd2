# Share Knowledge
extends Item



func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Share Knowledge[/color]\n"
	text += "Every 15 seconds this tower loses 10 experience to teach other random towers in 400 range. Up to five towers in range gain an equal split of 8 experience, plus 1 experience for each tower affected. This ability doesn't work if the item carrier is not at least level 2 and is unaffected by tower exp ratios.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func periodic(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var next: Tower
	var in_range: Iterate
	var count: int
	var experience: float

#	test if tower is level 2 or higher
	if tower.get_level() > 1:
#		test, if there are towers in range
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 400)
		count = min(5, in_range.count())

		if count > 0:
# 			(8 + number of towers) / number of towers
			experience = (8.0 + count) / count
			tower.remove_exp_flat(10)

			while true:
				next = in_range.next_random()

				if next == null:
					break

				next.add_exp_flat(experience)
				SFX.sfx_at_unit("PolyMorphTarget.mdl", next)
				count = count - 1

				if count == 0:
					break
