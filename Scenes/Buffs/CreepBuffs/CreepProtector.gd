class_name CreepProtector extends BuffType


# TODO: how close does the champion have to be to dying
# creep? Set it to 400.

# TODO: is "reducing damage by 130%" correct. How can you reduce by 130%.

# TODO: how long does the curse last? Set it to 10s for now.

var protector_curse: BuffType


func _init(parent: Node):
	super("creep_protector", 0, 0, true, parent)

	add_event_on_death(on_death)

	protector_curse = BuffType.new("protector_curse", 10.0, 0, false, self
		)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, -1.3, 0.0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, -2, 0.0)
	protector_curse.set_buff_modifier(modifier)


func on_death(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	var attacker: Unit = event.get_target()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.CREEPS + TargetType.SIZE_CHAMPION), 400.0)

	while true:
		var champion: Unit = I.next()

		if champion == null:
			break

		if champion == creep:
			break

		protector_curse.apply(champion, attacker, 0)

		break
