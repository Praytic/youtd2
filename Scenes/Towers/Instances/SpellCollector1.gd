extends Tower


# NOTE: original script has a bug where if multiple towers
# from Spell Collectors family are built, then only one
# tower will receive bonuses when other towers cast spells.
# Didn't fix this bug, translated version also behaves like
# this. If you want to fix this, search for other towers
# with a similar effect - they also use an aura to detect
# some event but share the bonuses correctly with all towers
# of the family.

# NOTE: reworked how delay between missiles is implemented.
# Original script uses JASS timer and Launch() function.
# Translated script does everything inside on_attack() and
# uses await().


var cedi_spell_pt: ProjectileType
var cedi_spell_gathering_bt: BuffType
var cedi_spell_missile_stacks_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {missile_count_max = 10, missile_count_max_add = 1, missile_damage = 2000, missile_damage_add = 80, missile_crit_chance = 0.050, missile_crit_chance_add = 0.002, missile_crit_dmg = 0.10, missile_crit_dmg_add = 0.004},
		2: {missile_count_max = 20, missile_count_max_add = 2, missile_damage = 4000, missile_damage_add = 160, missile_crit_chance = 0.075, missile_crit_chance_add = 0.003, missile_crit_dmg = 0.15, missile_crit_dmg_add = 0.006},
	}


var AURA_RANGE: float = 650
var BARRAGE_CHANCE: float = 0.20
var BARRAGE_CHANCE_ADD: float = 0.008


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var barrage_chance: String = Utils.format_percent(BARRAGE_CHANCE, 2)
	var barrage_chance_add: String = Utils.format_percent(BARRAGE_CHANCE_ADD, 2)
	var missile_count_max: String = Utils.format_float(_stats.missile_count_max, 2)
	var missile_count_max_add: String = Utils.format_float(_stats.missile_count_max_add, 2)
	var missile_damage: String = Utils.format_float(_stats.missile_damage, 2)
	var missile_damage_add: String = Utils.format_float(_stats.missile_damage_add, 2)
	var missile_crit_chance: String = Utils.format_percent(_stats.missile_crit_chance, 2)
	var missile_crit_chance_add: String = Utils.format_percent(_stats.missile_crit_chance_add, 2)
	var missile_crit_dmg: String = Utils.format_percent(_stats.missile_crit_dmg, 2)
	var missile_crit_dmg_add: String = Utils.format_percent(_stats.missile_crit_dmg_add, 2)

	var text: String = ""

	text += "[color=GOLD]Magical Barrage[/color]\n"
	text += "Whenever this tower attacks it has a %s chance to launch a magical missile. Whenever a tower in %s range casts a spell, the amount of missiles on attack is increased by 1 for a duration equal to the casting tower's ability's cooldown. The Spell Collector can shoot up to %s missiles per attack. Each missile deals %s spell damage. Each additional missile has %s higher crit chance and %s higher crit damage than the previous one.\n" % [barrage_chance, aura_range, missile_count_max, missile_damage, missile_crit_chance, missile_crit_dmg]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % barrage_chance_add
	text += "+%s spell damage\n" % missile_damage_add
	text += "+%s spell crit chance\n" % missile_crit_chance_add
	text += "+%s spell crit damage\n" % missile_crit_dmg_add
	text += "+%s max missiles every 5 levels\n" % missile_count_max_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Magical Barrage[/color]\n"
	text += "Whenever this tower attacks it has a chance to launch magical missiles. The amount of missiles increases whenever a nearby tower casts a spell.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	cedi_spell_pt = ProjectileType.create_interpolate("FarseerMissile.mdl", 1200, self)
	cedi_spell_pt.set_event_on_interpolation_finished(cedi_spell_pt_on_hit)

	cedi_spell_gathering_bt = BuffType.create_aura_effect_type("cedi_spell_gathering_bt", true, self)
	cedi_spell_gathering_bt.set_buff_icon("@@2@@")
	cedi_spell_gathering_bt.add_event_on_spell_casted(cedi_spell_gathering_bt_on_spell_casted)
	cedi_spell_gathering_bt.set_buff_tooltip("Title\nDescription.")
	cedi_spell_gathering_bt.set_buff_tooltip("Spell Gathering\nThis tower is under the effect of Spell Gathering; it will empower a nearby tower when it casts spells.")

	cedi_spell_missile_stacks_bt = BuffType.new("cedi_spell_missile_stacks_bt", 20, 0, true, self)
	cedi_spell_missile_stacks_bt.set_buff_icon("@@2@@")
	cedi_spell_gathering_bt.set_buff_tooltip("Missile Barrage\nThis tower is under the effect of Missile Barrage; it will launch magical missiles when it attacks.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Spells Harvested")

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = cedi_spell_gathering_bt
	add_aura(aura)


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var chance: float = BARRAGE_CHANCE + BARRAGE_CHANCE_ADD * tower.get_level()
	var missile_crit_chance: float = _stats.missile_crit_chance + _stats.missile_crit_chance_add * tower.get_level()
	var missile_crit_dmg: float = _stats.missile_crit_dmg + _stats.missile_crit_dmg_add * tower.get_level()
	var missile_count_max: int = _stats.missile_count_max + _stats.missile_count_max_add * tower.get_level() / 5
	var stacks_buff: Buff = tower.get_buff_of_type(cedi_spell_missile_stacks_bt)

	var missile_count: int
	if stacks_buff != null:
		missile_count = min(stacks_buff.get_level() + 1, missile_count_max)
	else:
		missile_count = 1

	var delay_between_missiles: float = max(0.2, tower.get_current_attack_speed() / missile_count)

	if !tower.calc_chance(chance):
		return
	
	for i in range(0, missile_count):
		if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(target):
			return

		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(cedi_spell_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, target, 0.0, 0.0, 0.0, true)
		var missile_number: int = i + 1
		projectile.user_real = missile_crit_chance * missile_number
		projectile.user_real2 = missile_crit_dmg * missile_number

		await get_tree().create_timer(delay_between_missiles).timeout


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var buff: Buff = tower.get_buff_of_type(cedi_spell_missile_stacks_bt)
	var lvl: int = 0

	if buff != null:
		lvl = min(buff.get_level() + 1, 10 + tower.get_level() / 5)

	var spells_harvested: String = Utils.format_float(lvl, 0)
	multiboard.set_value(0, spells_harvested)

	return multiboard


func cedi_spell_gathering_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()

	var stacks_buff: Buff = caster.get_buff_of_type(cedi_spell_missile_stacks_bt)
	var stacks_count: int
	if stacks_buff != null:
		stacks_count = stacks_buff.get_level() + 1
	else:
		stacks_count = 1

	stacks_buff = cedi_spell_missile_stacks_bt.apply(caster, caster, stacks_count)

	var autocast: Autocast = event.get_autocast_type()
	var autocast_cooldown: float = autocast.get_cooldown()

	await get_tree().create_timer(autocast_cooldown).timeout

	if Utils.unit_is_valid(caster):
		stacks_buff = caster.get_buff_of_type(cedi_spell_missile_stacks_bt)

		if stacks_buff != null:
			stacks_buff.set_level(stacks_buff.get_level() - 1)
			if stacks_buff.get_level() == 0:
				stacks_buff.remove_buff()


func cedi_spell_pt_on_hit(p: Projectile, target: Unit):
	var caster: Tower = p.get_caster()
	var damage: float = _stats.missile_damage + _stats.missile_damage_add * caster.get_level()

	if target != null && caster != null:
		caster.do_spell_damage(target, damage, caster.calc_spell_crit(p.user_real, p.user_real2))
