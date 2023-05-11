class_name CreepNecromancer extends BuffType


# TODO: implement raising the dead


func _init(parent: Node):
	super("creep_necromancer", 0, 0, true, parent)

	add_event_on_death(on_death)


func on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.CREEPS + TargetType.SIZE_CHAMPION), 400.0)

	while true:
		var champion: Unit = I.next()

		if champion == null:
			break

		if champion == creep:
			break

		# TODO: raise the dead here. Spend mana of champion
		# and spawn a skeleton from a corpse, delayed by 3
		# seconds.

		break
