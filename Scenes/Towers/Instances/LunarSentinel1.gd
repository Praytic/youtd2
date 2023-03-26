extends Tower


var sir_moonp_buff: BuffType

# NOTE: I think there's a typo in tier 4 because for all
# other tiers spell_damage_chance_add is the same as
# spell_damage_add, but for tier 4 it's 1000 instead of 100.
# Leaving as in original.

func _get_tier_stats() -> Dictionary:
	return {
		1: {spell_damage = 50, spell_damage_15 = 70, spell_damage_add = 2, spell_damage_chance_add = 2, buff_power = 120, buff_power_15 = 150},
		2: {spell_damage = 500, spell_damage_15 = 700, spell_damage_add = 20, spell_damage_chance_add = 20, buff_power = 160, buff_power_15 = 200},
		3: {spell_damage = 1500, spell_damage_15 = 2100, spell_damage_add = 60, spell_damage_chance_add = 60, buff_power = 200, buff_power_15 = 250},
		4: {spell_damage = 2500, spell_damage_15 = 3500, spell_damage_add = 100, spell_damage_chance_add = 1000, buff_power = 240, buff_power_15 = 300},
	}


func tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.the_range = 1200
	autocast.target_self = false
	autocast.target_art = "Abilities/Spells/Items/AIil/AIilTarget.mdl"
	autocast.cooldown = 2
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = 0
	autocast.target_type = null
	autocast.auto_range = 1200
	autocast.handler = _on_autocast

	add_autocast(autocast)

	var m: Modifier = Modifier.new()
	sir_moonp_buff = BuffType.new("sir_moonp_buff", 0, 0, false)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0, 0.001)
	sir_moonp_buff.set_buff_icon("'@@0@@")
	sir_moonp_buff.set_stacking_group("sir_moonp_buff")


func _on_autocast(event: Event):
	var tower = self

	var level: int = tower.get_level()
	var target: Unit = event.get_target()

	if level < 15:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())
	else:
		tower.do_spell_damage(target, _stats.spell_damage_15 + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(0.125 + level * 0.005) == true:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_chance_add, tower.calc_spell_crit_no_bonus())

		var cb_stun: BuffType = CbStun.new("cb_stun", 0, 0, false)

		if level < 25:
			cb_stun.apply_only_timed(tower, target, 0.3)
		else:
			cb_stun.apply_only_timed(tower, target, 0.4)

		if level < 15:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power, 2.5)
		else:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power_15, 2.5)
