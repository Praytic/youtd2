extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug in original script,
# where twister debuff from Harpy Queen (tier 2) was not
# causing creeps to suffer 18% extra dmg from storm towers,
# as described in the tooltip. The bug was caused by
# twister_level_base value being equal to 20 which caused
# the mod value to be 12% instead of 18%. Fixed by changing
# twister_level_base for tier 2 to 80.


var sparks_bt: BuffType
var twister_bt: BuffType
var missile_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {sparks_spell_damage = 0.15, sparks_spell_damage_add = 0.002, sparks_spell_crit_chance = 0.100, sparks_spell_crit_chance_add = 0.001, twister_chance = 0.08, twister_chance_add = 0.003, twister_tornado_count = 2, twister_mod_storm_dmg = 0.10, twister_mod_storm_dmg_add = 0.004, sparks_level_base = 0, sparks_level_multiply = 1, twister_level_base = 0, twister_level_multiply = 4},
		2: {sparks_spell_damage = 0.20, sparks_spell_damage_add = 0.004, sparks_spell_crit_chance = 0.125, sparks_spell_crit_chance_add = 0.002, twister_chance = 0.12, twister_chance_add = 0.005, twister_tornado_count = 3, twister_mod_storm_dmg = 0.18, twister_mod_storm_dmg_add = 0.007, sparks_level_base = 25, sparks_level_multiply = 2, twister_level_base = 80, twister_level_multiply = 7},
	}

const SPARKS_DURATION: float = 7.5
const SPARKS_DURATION_ADD: float = 0.3
const TWISTER_DURATION: float = 5.0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	sparks_bt = BuffType.new("sparks_bt", 0, 0, true, self)
	var sparks_mod: Modifier = Modifier.new()
	sparks_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.001)
	sparks_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.15, 0.002)
	sparks_bt.set_buff_modifier(sparks_mod)
	sparks_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	sparks_bt.set_buff_tooltip("Sparks\nIncreases spell damage and spell crit chance.")

	twister_bt = BuffType.new("twister_bt", TWISTER_DURATION, 0, false, self)
	var twister_mod: Modifier = Modifier.new()
	twister_mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, 0.10, 0.001)
	twister_bt.set_buff_modifier(twister_mod)
	twister_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	twister_bt.set_buff_tooltip("Twisted\nIncreases damage taken from Storm towers.")

	missile_pt = ProjectileType.create("path_to_projectile_sprite", 4, 1000, self)
	missile_pt.enable_homing(harpy_missile_on_hit, 0)


func on_attack(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var twister_chance: float = _stats.twister_chance + _stats.twister_chance_add * tower.get_level()
	var tornado_count: int = _stats.twister_tornado_count

	if !tower.calc_chance(twister_chance):
		return

	CombatLog.log_ability(tower, null, "Twister")

	while true:
		var target: Unit = it.next_random()

		if target == null:
			break

		var projectile: Projectile = Projectile.create_from_unit_to_unit(missile_pt, tower, 1, 0, tower, target, true, false, false)
		projectile.set_projectile_scale(0.7)

		tornado_count -= 1
		if tornado_count == 0:
			break


func on_autocast(event: Event):
	var target: Tower = event.get_target()
	var buff_level: int = _stats.sparks_level_base + _stats.sparks_level_multiply * tower.get_level()
	var buff_duration: float = SPARKS_DURATION + SPARKS_DURATION_ADD * tower.get_level()
	sparks_bt.apply_custom_timed(tower, target, buff_level, buff_duration)


func harpy_missile_on_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var buff_level: int = _stats.twister_level_base + _stats.twister_level_multiply * tower.get_level()
	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())
	twister_bt.apply(tower, creep, buff_level)
