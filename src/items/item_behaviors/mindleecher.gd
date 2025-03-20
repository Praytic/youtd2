extends ItemBehavior


func on_autocast(_event: Event):
	var tower: Tower = item.get_carrier()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 450)
	var next: Unit

	while true:
		next = it.next_random()

		if next == null:
			break

		if next != tower && next.get_exp() > 0:
			break

	if next != null:
		tower.add_exp_flat(next.remove_exp_flat(Globals.synced_rng.randi_range(15, 60)))
		Effect.create_simple_at_unit("res://src/effects/animated_dead_target.tscn", next, Unit.BodyPart.HEAD)
		Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", next, Unit.BodyPart.HEAD)
