class_name CreepSpellbinder extends BuffType


var slow_aura_effect: BuffType
var cb_silence: BuffType


func _init(parent: Node):
	super("creep_spellbinder", 0, 0, true, parent)

	cb_silence = CbSilence.new("cb_silence", 0, 0, false, self)

	add_periodic_event(on_periodic, 5.0)

	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -2.0, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)
	slow_aura_effect.set_buff_tooltip("Drain gang\nThis tower's mana is being drained by a nearby creep. It's mana regeneration is decreased by 200%.")


func on_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.TOWERS), 1100.0)

	var zap_count: int = 0

	while true:
		var tower: Unit = I.next_random()

		if tower == null:
			break

		var creep_mana_before: float = Unit.get_unit_state(creep, Unit.State.MANA)

		if creep_mana_before < 50:
			break

		if zap_count >= 3:
			break

		var tower_mana_before: float = Unit.get_unit_state(tower, Unit.State.MANA)
		var stolen_mana: float = tower_mana_before * 0.3

		var creep_mana_after: float = creep_mana_before - 50 + stolen_mana
		Unit.set_unit_state(creep, Unit.State.MANA, creep_mana_after)

		var tower_mana_after: float = tower_mana_before - stolen_mana
		Unit.set_unit_state(tower, Unit.State.MANA, tower_mana_after)

		cb_silence.apply_only_timed(creep, tower, 5.0) 

		zap_count += 1
