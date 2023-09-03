extends Tower


var sir_moonp_buff: BuffType
var cb_stun: BuffType

# NOTE: I think there's a typo in tier 4 because for all
# other tiers spell_damage_chance_add is the same as
# spell_damage_add, but for tier 4 it's 1000 instead of 100.
# Leaving as in original.

func get_tier_stats() -> Dictionary:
	return {
		1: {spell_damage = 50, spell_damage_15 = 70, spell_damage_add = 2, spell_damage_chance_add = 2, buff_power = 120, buff_power_15 = 150},
		2: {spell_damage = 500, spell_damage_15 = 700, spell_damage_add = 20, spell_damage_chance_add = 20, buff_power = 160, buff_power_15 = 200},
		3: {spell_damage = 1500, spell_damage_15 = 2100, spell_damage_add = 60, spell_damage_chance_add = 60, buff_power = 200, buff_power_15 = 250},
		4: {spell_damage = 2500, spell_damage_15 = 3500, spell_damage_add = 100, spell_damage_chance_add = 1000, buff_power = 240, buff_power_15 = 300},
	}


func get_lunar_grace_description() -> String:
	var spell_damage: String = Utils.format_float(_stats.spell_damage, 2)
	var spell_damage_add: String = Utils.format_float(_stats.spell_damage_add, 2)
	var damage_from_spells: String = Utils.format_percent(_stats.buff_power * 0.1 * 0.01, 2)
	var damage_at_15: String = Utils.format_float(_stats.spell_damage_15 - _stats.spell_damage, 2)
	var damage_from_spells_at_15: String = Utils.format_percent((_stats.buff_power_15 - _stats.buff_power)  * 0.1 * 0.01, 2)

	var text: String = ""

	text += "Smites a target creep dealing %s spelldamage to it. There is a 12.5%% chance to empower the smite with lunar energy dealing %s additional spell damage, stunning the target for 0.3 seconds and making it receive %s more damage from spells for 2.5 seconds.\n" % [spell_damage, spell_damage, damage_from_spells]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s inital and chanced spell damage\n" % spell_damage_add
	text += "+0.5% chance\n"
	text += "+%s initial damage at level 15\n" % damage_at_15
	text += "+%s spell damage received at level 15\n" % damage_from_spells_at_15
	text += "+0.1 seconds stun at level 25"

	return text


func tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Lunar Grace"
	autocast.description = get_lunar_grace_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = "Abilities/Spells/Items/AIil/AIilTarget.mdl"
	autocast.cooldown = 2
	autocast.is_extended = true
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 1200
	autocast.handler = on_autocast

	add_autocast(autocast)

	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)

	var m: Modifier = Modifier.new()
	sir_moonp_buff = BuffType.new("sir_moonp_buff", 0, 0, false, self)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0, 0.001)
	sir_moonp_buff.set_buff_icon("'@@0@@")
	sir_moonp_buff.set_stacking_group("sir_moonp_buff")

	sir_moonp_buff.set_buff_tooltip("Lunar Energy\nThis unit has been hit with Lunar Energy; it will receive more damage from spells.")


func on_autocast(event: Event):
	var tower = self

	var level: int = tower.get_level()
	var target: Unit = event.get_target()

	if level < 15:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())
	else:
		tower.do_spell_damage(target, _stats.spell_damage_15 + level * _stats.spell_damage_add, tower.calc_spell_crit_no_bonus())

	if tower.calc_chance(0.125 + level * 0.005) == true:
		tower.do_spell_damage(target, _stats.spell_damage + level * _stats.spell_damage_chance_add, tower.calc_spell_crit_no_bonus())

		if level < 25:
			cb_stun.apply_only_timed(tower, target, 0.3)
		else:
			cb_stun.apply_only_timed(tower, target, 0.4)

		if level < 15:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power, 2.5)
		else:
			sir_moonp_buff.apply_advanced(tower, target, 0, _stats.buff_power_15, 2.5)
