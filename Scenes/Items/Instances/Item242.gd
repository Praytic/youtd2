# Old Hunter
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Old Hunter[/color]\n"
	text += "After each kill, the carrier transfers 1 flat experience to up to 5 random towers in 500 range. The carrier must be at least level 5 to trigger this ability.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var next: Tower
	var in_range: Iterate
	var count: int

#	test if tower is minimum lvl 5
	if tower.get_level() >= 5:
#		test, if there are towers in range
		in_range = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
		count = min(5, in_range.count())

		if count > 0:
			tower.remove_exp_flat(count)

			while true:
				next = in_range.next_random()

				if next == null:
					break

				next.add_exp_flat(1)
				SFX.sfx_at_unit("AnimateDeadTarget.mdl", next)
				count = count - 1

				if count == 0:
					break

			if next != null:
				in_range.destroy()
		else:
			in_range.destroy()
