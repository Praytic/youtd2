extends Tower


# NOTE: fixed bug in original script, where twister debuff
# from Harpy Queen (tier 2) was not causing creeps to suffer
# 18% extra dmg from storm towers, as described in the
# tooltip. The bug was caused by twister_level_base value
# being equal to 20 which caused the mod value to be 12%
# instead of 18%. Fixed by changing twister_level_base for
# tier 2 to 80.


var sparks_bt: BuffType
var twister_bt: BuffType
var harpy_missile_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {sparks_spell_damage = 0.15, sparks_spell_damage_add = 0.002, sparks_spell_crit_chance = 0.100, sparks_spell_crit_chance_add = 0.001, twister_chance = 0.08, twister_chance_add = 0.003, twister_tornado_count = 2, twister_mod_storm_dmg = 0.10, twister_mod_storm_dmg_add = 0.004, sparks_level_base = 0, sparks_level_multiply = 1, twister_level_base = 0, twister_level_multiply = 4},
		2: {sparks_spell_damage = 0.20, sparks_spell_damage_add = 0.004, sparks_spell_crit_chance = 0.125, sparks_spell_crit_chance_add = 0.002, twister_chance = 0.12, twister_chance_add = 0.005, twister_tornado_count = 3, twister_mod_storm_dmg = 0.18, twister_mod_storm_dmg_add = 0.007, sparks_level_base = 25, sparks_level_multiply = 2, twister_level_base = 80, twister_level_multiply = 7},
	}


const SPARKS_RANGE: float = 500
const SPARKS_DURATION: float = 7.5
const SPARKS_DURATION_ADD: float = 0.3
const TWISTER_DURATION: float = 5.0


func get_ability_description() -> String:
	var twister_chance: String = Utils.format_percent(_stats.twister_chance, 2)
	var twister_chance_add: String = Utils.format_percent(_stats.twister_chance_add, 2)
	var twister_tornado_count: String = Utils.format_float(_stats.twister_tornado_count, 2)
	var twister_mod_storm_dmg: String = Utils.format_percent(_stats.twister_mod_storm_dmg, 2)
	var twister_mod_storm_dmg_add: String = Utils.format_percent(_stats.twister_mod_storm_dmg_add, 2)
	var twister_duration: String = Utils.format_float(TWISTER_DURATION, 2)

	var text: String = ""

	text += "[color=GOLD]Twister[/color]\n"
	text += "Attacks have a %s chance to summon %s tornados towards two random creeps in attack range of the harpy. Upon hit each tornado deals this tower's attack damage to the target and makes it suffer %s additional damage from Storm towers for %s seconds.\n" % [twister_chance, twister_tornado_count, twister_mod_storm_dmg, twister_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % twister_chance_add
	text += "+%s additional damage taken\n" % twister_mod_storm_dmg_add

	return text


func get_autocast_description() -> String:
	var sparks_range: String = Utils.format_float(SPARKS_RANGE, 2)
	var sparks_spell_damage: String = Utils.format_percent(_stats.sparks_spell_damage, 2)
	var sparks_spell_damage_add: String = Utils.format_percent(_stats.sparks_spell_damage_add, 2)
	var sparks_spell_crit_chance: String = Utils.format_percent(_stats.sparks_spell_crit_chance, 2)
	var sparks_spell_crit_chance_add: String = Utils.format_percent(_stats.sparks_spell_crit_chance_add, 2)
	var sparks_duration: String = Utils.format_float(SPARKS_DURATION, 2)
	var sparks_duration_add: String = Utils.format_float(SPARKS_DURATION_ADD, 2)

	var text: String = ""

	text += "Increases the spell damage for a tower in %s range by %s and it's spell critical strike chance by %s. Lasts %s seconds.\n" % [sparks_range, sparks_spell_damage, sparks_spell_crit_chance, sparks_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % sparks_spell_damage_add
	text += "+%s spell critical strike chance\n" % sparks_spell_crit_chance_add
	text += "+%s seconds duration\n" % sparks_duration_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(_modifier: Modifier):
	_set_attack_style_bounce(2, 0.25)


func tower_init():
	sparks_bt = BuffType.new("sparks_bt", 0, 0, true, self)
	var sparks_mod: Modifier = Modifier.new()
	sparks_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.001)
	sparks_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.15, 0.002)
	sparks_bt.set_buff_modifier(sparks_mod)
	sparks_bt.set_buff_icon("@@0@@")
	sparks_bt.set_buff_tooltip("Sparks\nThis tower is affected by Sparks; it deals extra spell damage and has increased spell crit chance.")

	twister_bt = BuffType.new("twister_bt", TWISTER_DURATION, 0, false, self)
	var twister_mod: Modifier = Modifier.new()
	twister_mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, 0.10, 0.001)
	twister_bt.set_buff_modifier(twister_mod)
	twister_bt.set_buff_icon("@@1@@")
	twister_bt.set_buff_tooltip("Twisted\nThis tower has been twisted; it will take extra damage from Storm towers.")

	harpy_missile_pt = ProjectileType.create("TornadoElementalSmall.mdl", 4, 1000, self)
	harpy_missile_pt.enable_homing(harpy_missile_on_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Sparks"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = "MonsoonBoltTarget.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = SPARKS_RANGE
	autocast.auto_range = SPARKS_RANGE
	autocast.cooldown = 2
	autocast.mana_cost = 22
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = twister_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_attack(_event: Event):
	var tower: Tower = self
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var twister_chance: float = _stats.twister_chance + _stats.twister_chance_add * tower.get_level()
	var tornado_count: int = _stats.twister_tornado_count

	if !tower.calc_chance(twister_chance):
		return

	while true:
		var target: Unit = it.next_random()

		if target == null:
			break

		var projectile: Projectile = Projectile.create_from_unit_to_unit(harpy_missile_pt, tower, 1, 0, tower, target, true, false, false)
		projectile.setScale(0.7)

		tornado_count -= 1
		if tornado_count == 0:
			break


func on_autocast(event: Event):
	var tower: Tower = self
	var target: Tower = event.get_target()
	var buff_level: int = _stats.sparks_level_base + _stats.sparks_level_multiply * tower.get_level()
	var buff_duration: float = SPARKS_DURATION + SPARKS_DURATION_ADD * tower.get_level()
	sparks_bt.apply_custom_timed(tower, target, buff_level, buff_duration)


func harpy_missile_on_hit(projectile: Projectile, creep: Unit):
	var tower: Tower = projectile.get_caster()
	var buff_level: int = _stats.twister_level_base + _stats.twister_level_multiply * tower.get_level()
	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())
	twister_bt.apply(tower, creep, buff_level)
