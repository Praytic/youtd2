class_name CreepSpellbinder extends BuffType

# NOTE: this special is not affected by silence, on purpose.
# This is how it was in the original game.


var silence_bt: BuffType


func _init(parent: Node):
	super("creep_spellbinder", 0, 0, true, parent)

	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	add_periodic_event(on_periodic, 5.0)


func on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.TOWERS), 1100.0)

	var zap_count: int = 0

	while true:
		var tower: Unit = I.next_random()

		if tower == null:
			break

		if zap_count >= 3:
			break

		if creep.get_mana() < 50:
			break

		creep.subtract_mana(50, true)

		var stolen_mana: float = tower.get_overall_mana() * 0.3
		creep.add_mana(stolen_mana)
		tower.subtract_mana(stolen_mana, true)

		silence_bt.apply_only_timed(creep, tower, 5.0) 

		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, creep, tower)
		lightning.modulate = Color.PURPLE
		lightning.set_lifetime(0.2)

		zap_count += 1
