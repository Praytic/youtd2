extends TowerBehavior


var wind_shear_bt: BuffType
var chainlightning_st: SpellType
var chainlightning_st_2: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {attack_speed = 0.10, buff_level = 0, user_real_base = 0, user_real_add = 1},
		2: {attack_speed = 0.15, buff_level = 5, user_real_base = 50, user_real_add = 3},
		3: {attack_speed = 0.20, buff_level = 10, user_real_base = 125, user_real_add = 6},
		4: {attack_speed = 0.25, buff_level = 15, user_real_base = 225, user_real_add = 10},
		5: {attack_speed = 0.30, buff_level = 20, user_real_base = 425, user_real_add = 18},
	}


func phantom_attack(event: Event):
	var b: Buff = event.get_buff()

	var twr: Tower = b.get_buffed_unit()

	if b.get_caster().get_level() < 20:
		if twr.calc_chance(0.25 * twr.get_base_attack_speed()):
			CombatLog.log_ability(twr, event.get_target(), "Wind Shear Bonus")

			chainlightning_st.target_cast_from_caster(twr, event.get_target(), 1.0 + b.user_real * 0.04, twr.calc_spell_crit_no_bonus())
	else:
		if twr.calc_chance(0.25 * twr.get_base_attack_speed()):
			CombatLog.log_ability(twr, event.get_target(), "Wind Shear Super Bonus")
			
			chainlightning_st_2.target_cast_from_caster(twr, event.get_target(), 1.0 + b.user_real * 0.04, twr.calc_spell_crit_no_bonus())


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(ModificationType.enm.MOD_ATTACKSPEED, _stats.attack_speed, 0.01)
	
	wind_shear_bt = BuffType.new("wind_shear_bt", 5.0, 0.1, true, self)
	
	wind_shear_bt.set_buff_modifier(m)
	
	wind_shear_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	
	wind_shear_bt.add_event_on_attack(phantom_attack)
	
	wind_shear_bt.set_buff_tooltip(tr("TQVI"))

	chainlightning_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 5.00, self)
	chainlightning_st.set_source_height(40.0)
	chainlightning_st.data.chain_lightning.damage = 100
	chainlightning_st.data.chain_lightning.damage_reduction = 0.25
	chainlightning_st.data.chain_lightning.chain_count = 3

	chainlightning_st_2 = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 5.00, self)
	chainlightning_st_2.set_source_height(40.0)
	chainlightning_st_2.data.chain_lightning.damage = 100
	chainlightning_st_2.data.chain_lightning.damage_reduction = 0.25
	chainlightning_st_2.data.chain_lightning.chain_count = 4


func on_autocast(event: Event):
	wind_shear_bt.apply_custom_timed(tower, event.get_target(), tower.get_level() + _stats.buff_level, 5.0 + tower.get_level() * 0.1).user_real = tower.get_level() * _stats.user_real_add + _stats.user_real_base
