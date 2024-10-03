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


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var spell_damage: String = Utils.format_float(_stats.spell_damage, 2)
	var spell_damage_add: String = Utils.format_float(_stats.spell_damage_add, 2)
	var damage_from_spells: String = Utils.format_percent(_stats.buff_level * 0.1 * 0.01, 2)
	var damage_at_15: String = Utils.format_float(_stats.spell_damage_15 - _stats.spell_damage, 2)
	var damage_from_spells_at_15: String = Utils.format_percent((_stats.buff_level_15 - _stats.buff_level)  * 0.1 * 0.01, 2)

	autocast.title = "Lunar Grace"
	autocast.icon = "res://resources/icons/orbs/moon.tres"
	autocast.description_short = "Smites a target creep dealing spell damage. There is also a chance to stun the creep and make it more vulnerable to spells.\n"
	autocast.description = "Smites a target creep dealing %s spell damage to it. There is also a 12.5%% chance to empower the smite with lunar energy dealing %s additional spell damage, stunning the target for 0.3 seconds and making it receive %s more damage from spells for 2.5 seconds.\n" % [spell_damage, spell_damage, damage_from_spells] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s inital and chanced spell damage\n" % spell_damage_add \
	+ "+0.5% chance\n" \
	+ "+%s initial damage at level 15\n" % damage_at_15 \
	+ "+%s spell damage received at level 15\n" % damage_from_spells_at_15 \
	+ "+0.1 seconds stun at level 25"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = "res://src/effects/spell_aiil.tscn"
	autocast.cooldown = 2
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.auto_range = 1200
	autocast.handler = on_autocast

	return [autocast]


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
