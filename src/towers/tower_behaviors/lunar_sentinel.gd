extends TowerBehavior


var lunar_energy_bt: BuffType
var stun_bt: BuffType

# NOTE: [ORIGINAL_GAME_BUG] Fixed bug for tier 4 tower. In
# original game, the "lunar_energy_dmg_add" value for tier 4
# was 1000 even though ability description says it's should
# be 100.


func get_tier_stats() -> Dictionary:
	return {
		1: {spell_damage = 50, spell_damage_15 = 70, spell_damage_add = 2, lunar_energy_dmg_add = 2, buff_level = 120, buff_level_15 = 150},
		2: {spell_damage = 500, spell_damage_15 = 700, spell_damage_add = 20, lunar_energy_dmg_add = 20, buff_level = 160, buff_level_15 = 200},
		3: {spell_damage = 1500, spell_damage_15 = 2100, spell_damage_add = 60, lunar_energy_dmg_add = 60, buff_level = 200, buff_level_15 = 250},
		4: {spell_damage = 2500, spell_damage_15 = 3500, spell_damage_add = 100, lunar_energy_dmg_add = 100, buff_level = 240, buff_level_15 = 300},
	}


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	var m: Modifier = Modifier.new()
	lunar_energy_bt = BuffType.new("lunar_energy_bt", 0, 0, false, self)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0, 0.001)
	lunar_energy_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")

	lunar_energy_bt.set_buff_tooltip("Lunar Energy\nIncreases spell damage taken.")


func on_autocast(event: Event):
	var level: int = tower.get_level()
	var target: Unit = event.get_target()

	if level < 15:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())
	else:
		tower.do_spell_damage(target, _stats.spell_damage_15 + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(0.125 + level * 0.005) == true:
		CombatLog.log_ability(tower, target, "Lunar Grace Bonus")

		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.lunar_energy_dmg_add, tower.calc_spell_crit_no_bonus())

		if level < 25:
			stun_bt.apply_only_timed(tower, target, 0.3)
		else:
			stun_bt.apply_only_timed(tower, target, 0.4)

		if level < 15:
			lunar_energy_bt.apply_custom_timed(tower, target, _stats.buff_level, 2.5)
		else:
			lunar_energy_bt.apply_custom_timed(tower, target, _stats.buff_level_15, 2.5)
