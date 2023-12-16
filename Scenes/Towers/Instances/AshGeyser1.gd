extends Tower


var drol_fireDot: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {firedot_level_add = 0, firedot_level_multiply = 1},
		2: {firedot_level_add = 50, firedot_level_multiply = 2},
		3: {firedot_level_add = 100, firedot_level_multiply = 3},
		4: {firedot_level_add = 150, firedot_level_multiply = 4},
		5: {firedot_level_add = 200, firedot_level_multiply = 5},
	}


func get_ability_description() -> String:
	var regen_reduction: String = Utils.format_percent(0.05 + _stats.firedot_level_add * 0.1 * 0.01, 2)
	var regen_reduction_add: String = Utils.format_percent(_stats.firedot_level_multiply * 0.1 * 0.01, 2)

	var text: String = ""

	text += "[color=GOLD]Ignite[/color]\n"
	text += "The geyser has a 30%% chance on damaging a creep to ignite the target, dealing 15%% of the tower's attack damage as spell damage per second and reducing the target's health regeneration by %s for 8 seconds.\n" % regen_reduction
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% attack damage\n"
	text += "+%s health regeneration reduction\n" % regen_reduction_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Ignite[/color]\n"
	text += "Damages a target over time and makes decreases target's health regeneration.\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	_set_attack_style_splash({175: 0.30})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, 0.20, 0.004)


func drol_fireDot_Damage(event: Event):
	var b: Buff = event.get_buff()

	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	var drol_fireMod: Modifier = Modifier.new()
	drol_fireDot = BuffType.new("drol_fireDot", 8, 0, false, self)
	drol_fireDot.set_buff_icon("@@0@@")
	drol_fireMod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.05, -0.001)
	drol_fireDot.set_buff_modifier(drol_fireMod)
	drol_fireDot.add_periodic_event(drol_fireDot_Damage, 1)

	drol_fireDot.set_buff_tooltip("On Fire\nThis unit is On Fire; it will take damage over time and it has reduced health regeneration.")


func on_damage(event: Event):
	var tower: Tower = self
	
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, event.get_target(), "Ignite")

	drol_fireDot.apply(tower, event.get_target(), tower.get_level() * _stats.firedot_level_multiply + _stats.firedot_level_add).user_real = tower.get_current_attack_damage_with_bonus() * (0.15 + tower.get_level() * 0.006)
