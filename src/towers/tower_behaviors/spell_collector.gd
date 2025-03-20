extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] (NOT FIXED) Original
# script has a bug where if multiple towers from Spell
# Collectors family are built, then only one tower will
# receive bonuses when other towers cast spells. Didn't fix
# this bug, translated version also behaves like this. If
# you want to fix this, check other tower scripts for an
# example fix. There are other towers with a similar effect
# - they also use an aura to detect some event but share the
# bonuses correctly with all towers of the family.

# NOTE: reworked how delay between missiles is implemented.
# Original script uses JASS timer and Launch() function.
# Translated script does everything inside on_attack() and
# uses await().


var spell_pt: ProjectileType
var spell_gathering_bt: BuffType
var missile_stacks_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {missile_count_max = 10, missile_count_max_add = 1, missile_damage = 2000, missile_damage_add = 80, missile_crit_chance = 0.050, missile_crit_chance_add = 0.002, missile_crit_dmg = 0.10, missile_crit_dmg_add = 0.004},
		2: {missile_count_max = 20, missile_count_max_add = 2, missile_damage = 4000, missile_damage_add = 160, missile_crit_chance = 0.075, missile_crit_chance_add = 0.003, missile_crit_dmg = 0.15, missile_crit_dmg_add = 0.006},
	}


var BARRAGE_CHANCE: float = 0.20
var BARRAGE_CHANCE_ADD: float = 0.008


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	spell_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1200, self)
	spell_pt.set_event_on_interpolation_finished(spell_pt_on_hit)

	spell_gathering_bt = BuffType.create_aura_effect_type("spell_gathering_bt", true, self)
	spell_gathering_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	spell_gathering_bt.add_event_on_spell_casted(spell_gathering_bt_on_spell_casted)
	spell_gathering_bt.set_buff_tooltip("Spell Gathering\nEmpowers a nearby tower when buffed tower casts spells.")

	missile_stacks_bt = BuffType.new("missile_stacks_bt", 20, 0, true, self)
	missile_stacks_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	missile_stacks_bt.set_buff_tooltip("Absorbed Missile\nMagical missiles are ready to be fired.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Spells Harvested")


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var chance: float = BARRAGE_CHANCE + BARRAGE_CHANCE_ADD * tower.get_level()
	var missile_crit_chance: float = _stats.missile_crit_chance + _stats.missile_crit_chance_add * tower.get_level()
	var missile_crit_dmg: float = _stats.missile_crit_dmg + _stats.missile_crit_dmg_add * tower.get_level()
	var missile_count_max: int = _stats.missile_count_max + _stats.missile_count_max_add * tower.get_level() / 5
	var stacks_buff: Buff = tower.get_buff_of_type(missile_stacks_bt)

	var missile_count: int
	if stacks_buff != null:
		missile_count = min(stacks_buff.get_level() + 1, missile_count_max)
	else:
		missile_count = 1

	var delay_between_missiles: float = max(0.2, tower.get_current_attack_speed() / missile_count)

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, null, "Magical Barrage")

	for i in range(0, missile_count):
		if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(target):
			return

		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(spell_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, target, 0.0, 0.0, 0.0, true)
		var missile_number: int = i + 1
		projectile.user_real = missile_crit_chance * missile_number
		projectile.user_real2 = missile_crit_dmg * missile_number

		await Utils.create_manual_timer(delay_between_missiles, self).timeout


func on_tower_details() -> MultiboardValues:
	var buff: Buff = tower.get_buff_of_type(missile_stacks_bt)
	var lvl: int = 0

	if buff != null:
		lvl = min(buff.get_level() + 1, 10 + tower.get_level() / 5)

	var spells_harvested: String = Utils.format_float(lvl, 0)
	multiboard.set_value(0, spells_harvested)

	return multiboard


func spell_gathering_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()

	var stacks_buff: Buff = caster.get_buff_of_type(missile_stacks_bt)
	var stacks_count: int
	if stacks_buff != null:
		stacks_count = stacks_buff.get_level() + 1
	else:
		stacks_count = 1

	stacks_buff = missile_stacks_bt.apply(caster, caster, stacks_count)
	stacks_buff.set_displayed_stacks(stacks_count)

	var autocast: Autocast = event.get_autocast_type()
	var autocast_cooldown: float = autocast.get_cooldown()

	await Utils.create_manual_timer(autocast_cooldown, self).timeout

	if Utils.unit_is_valid(caster):
		stacks_buff = caster.get_buff_of_type(missile_stacks_bt)

		if stacks_buff != null:
			stacks_buff.set_level(stacks_buff.get_level() - 1)
			stacks_buff.set_displayed_stacks(stacks_buff.get_level())
			if stacks_buff.get_level() == 0:
				stacks_buff.remove_buff()


func spell_pt_on_hit(p: Projectile, target: Unit):
	var caster: Tower = p.get_caster()
	var damage: float = _stats.missile_damage + _stats.missile_damage_add * caster.get_level()

	if target != null && caster != null:
		caster.do_spell_damage(target, damage, caster.calc_spell_crit(p.user_real, p.user_real2))
