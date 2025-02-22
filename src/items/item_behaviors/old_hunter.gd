extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_damage)


func on_damage(_event: Event):
	var tower: Tower = item.get_carrier()
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
				Effect.create_simple_at_unit("res://src/effects/animated_dead_target.tscn", next)
				count = count - 1

				if count == 0:
					break
