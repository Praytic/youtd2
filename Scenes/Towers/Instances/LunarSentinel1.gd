extends Tower

# TODO: visual


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


func _ready():
	var autocast_data: Autocast.Data = Autocast.Data.new()
	autocast_data.caster_art = ""
	autocast_data.num_buffs_before_idle = 0
	autocast_data.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast_data.the_range = 1200
	autocast_data.target_self = false
	autocast_data.target_art = "Abilities/Spells/Items/AIil/AIilTarget.mdl"
	autocast_data.cooldown = 2
	autocast_data.is_extended = true
	autocast_data.mana_cost = 0
	autocast_data.buff_type = 0
	autocast_data.target_type = null
	autocast_data.auto_range = 1200

	var triggers_buff = TriggersBuff.new()
	triggers_buff.add_autocast(autocast_data, self, "_on_autocast")
	triggers_buff.apply_to_unit_permanent(self, self, 0)


func _on_autocast(event: Event):
	var tower = self

	var m: Modifier = Modifier.new()
	var sir_moonp_buff: Buff = Buff.new("sir_moonp_buff", 0, 0, false)
	# m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0, 0.001)
	m.add_modification(Modification.Type.MOD_MOVE_SPEED, 0, 0.001)
	sir_moonp_buff.set_buff_icon("'@@0@@")
	sir_moonp_buff.set_stacking_group("sir_moonp_buff")

	var level: int = tower.get_level()
	var target: Unit = event.get_target()

	if level < 15:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus(), false)
	else:
		tower.do_spell_damage(target, _stats.spell_damage_15 + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus(), false)

	if tower.calc_chance(0.125 + level * 0.005) == true:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_chance_add, tower.calc_spell_crit_no_bonus(), false)

		var cb_stun: Buff = CbStun.new("cb_stun", 0, 0, false)

		if level < 25:
			cb_stun.apply_only_timed(tower, target, 0.3)
		else:
			cb_stun.apply_only_timed(tower, target, 0.4)

		if level < 15:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power, 2.5)
		else:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power_15, 2.5)
