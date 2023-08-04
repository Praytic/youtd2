class_name CreepSpellbinder extends BuffType


var slow_aura_effect: BuffType
var cb_silence: BuffType


func _init(parent: Node):
	super("creep_spellbinder", 0, 0, true, parent)

	cb_silence = CbSilence.new("cb_silence", 0, 0, false, self)

	add_event_on_create(on_create)

	slow_aura_effect = BuffType.create_aura_effect_type("creep_slow_aura_effect", false, self)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -2.0, 0.0)
	slow_aura_effect.set_buff_modifier(modifier)


func on_create(event: Event):
	var autocast: Autocast = Autocast.make()
	autocast.title = "none"
	autocast.description = "none"
	autocast.icon = "none"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 20
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 0
	autocast.handler = on_autocast

	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.add_autocast(autocast)


func on_autocast(event: Event):
	var creep: Unit = event.get_target()

	var I: Iterate = Iterate.over_units_in_range_of_caster(creep, TargetType.new(TargetType.TOWERS), 1100.0)

	var zap_count: int = 0

	while true:
		var tower: Unit = I.next_random()

		if tower == null:
			break

		var creep_mana_before: float = Unit.get_unit_state(creep, Unit.State.MANA)

		if zap_count >= 3:
			break

		var tower_mana_before: float = Unit.get_unit_state(tower, Unit.State.MANA)
		var stolen_mana: float = tower_mana_before * 0.3

		var creep_mana_after: float = creep_mana_before + stolen_mana
		Unit.set_unit_state(creep, Unit.State.MANA, creep_mana_after)

		var tower_mana_after: float = tower_mana_before - stolen_mana
		Unit.set_unit_state(tower, Unit.State.MANA, tower_mana_after)

		cb_silence.apply_only_timed(creep, tower, 5.0) 

		zap_count += 1
