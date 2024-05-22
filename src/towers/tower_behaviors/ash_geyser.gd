extends TowerBehavior


var ignite_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {firedot_level_add = 0, firedot_level_multiply = 1},
		2: {firedot_level_add = 50, firedot_level_multiply = 2},
		3: {firedot_level_add = 100, firedot_level_multiply = 3},
		4: {firedot_level_add = 150, firedot_level_multiply = 4},
		5: {firedot_level_add = 200, firedot_level_multiply = 5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var regen_reduction: String = Utils.format_percent(0.05 + _stats.firedot_level_add * 0.1 * 0.01, 2)
	var regen_reduction_add: String = Utils.format_percent(_stats.firedot_level_multiply * 0.1 * 0.01, 2)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ignite"
	ability.icon = "res://resources/icons/misc/teapot_04.tres"
	ability.description_short = "Chance to ignite hit creeps, dealing a portion of tower's attack damage as spell damage per second and reducing target's health regeneration.\n"
	ability.description_full = "30%% chance to ignite hit creeps, dealing 15%% of tower's attack damage as spell damage per second and reducing target's health regeneration by %s for 8 seconds.\n" % regen_reduction \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% attack damage\n" \
	+ "+%s health regeneration reduction\n" % regen_reduction_add

	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({175: 0.30})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, 0.20, 0.004)


# NOTE: drol_fireDot_Damage() in original script
func ignite_bt_periodic(event: Event):
	var b: Buff = event.get_buff()

	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", 8, 0, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	ignite_bt.set_buff_tooltip("On Fire\nDeals spell damage over time and reduces health regeneration.")
	ignite_bt.add_periodic_event(ignite_bt_periodic, 1)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.05, -0.001)
	ignite_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, event.get_target(), "Ignite")

	ignite_bt.apply(tower, event.get_target(), tower.get_level() * _stats.firedot_level_multiply + _stats.firedot_level_add).user_real = tower.get_current_attack_damage_with_bonus() * (0.15 + tower.get_level() * 0.006)
