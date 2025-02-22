extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
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
			CombatLog.log_item_ability(item, null, "Share Knowledge")

# 			(8 + number of towers) / number of towers
			experience = (8.0 + count) / count
			tower.remove_exp_flat(10)

			while true:
				next = in_range.next_random()

				if next == null:
					break

				next.add_exp_flat(experience)
				Effect.create_simple_at_unit("res://src/effects/polymorph_target.tscn", next)
				count = count - 1

				if count == 0:
					break
