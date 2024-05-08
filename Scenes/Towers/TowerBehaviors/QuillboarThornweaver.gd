extends TowerBehavior


var quillspray_pt: ProjectileType
var thorns_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {occasional_quillspray_chance = 0.12, occasional_quillspray_chance_add = 0.0015, double_chance = 0.05, triple_chance = 0.03},
		2: {occasional_quillspray_chance = 0.15, occasional_quillspray_chance_add = 0.0018, double_chance = 0.07, triple_chance = 0.05},
		3: {occasional_quillspray_chance = 0.18, occasional_quillspray_chance_add = 0.0021, double_chance = 0.09, triple_chance = 0.07},
	}


const QUILLSPRAY_STACKS_MAX: int = 40
const QUILLSPRAY_STACK_BONUS: float = 0.11
const QUILLSPRAY_DAMAGE_RATIO: float = 0.30
const QUILLSPRAY_DAMAGE_RATIO_ADD: float = 0.002
const QUILLSPRAY_DEBUFF_DURATION: float = 1.5
const QUILLSPRAY_RANGE: float = 800


func get_ability_info_list() -> Array[AbilityInfo]:
	var occasional_quillspray_chance: String = Utils.format_percent(_stats.occasional_quillspray_chance, 2)
	var occasional_quillspray_chance_add: String = Utils.format_percent(_stats.occasional_quillspray_chance_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Occasional Quillspray"
	ability.description_short = "On attack this tower has a chance to trigger a Quillspray.\n"
	ability.description_full = "On attack this tower has a %s chance to trigger a Quillspray.\n" % occasional_quillspray_chance \
	+ " \n" \
	+ "Hint: This Quillspray costs no mana.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % occasional_quillspray_chance_add
	list.append(ability)

	return list


func get_autocast_description() -> String:
	var quillspray_stacks_max: String = Utils.format_float(QUILLSPRAY_STACKS_MAX, 2)
	var quillspray_stack_bonus: String = Utils.format_percent(QUILLSPRAY_STACK_BONUS, 2)
	var quillspray_damage_ratio: String = Utils.format_percent(QUILLSPRAY_DAMAGE_RATIO, 2)
	var quillspray_damage_ratio_add: String = Utils.format_percent(QUILLSPRAY_DAMAGE_RATIO_ADD, 2)
	var quillspray_debuff_duration: String = Utils.format_float(QUILLSPRAY_DEBUFF_DURATION, 2)
	var quillspray_range: String = Utils.format_float(QUILLSPRAY_RANGE, 2)
	var double_chance: String = Utils.format_percent(_stats.double_chance, 2)
	var triple_chance: String = Utils.format_percent(_stats.triple_chance, 2)

	var text: String = ""

	text += "This tower deals %s of its attack damage as physical damage to every unit in %s range around it. A creep hit by a Quillspray receives %s more damage than it did from the previous Quillspray, if hit again within %s seconds. This effect stacks up to %s times.\n" % [quillspray_damage_ratio, quillspray_range, quillspray_stack_bonus, quillspray_debuff_duration, quillspray_stacks_max]
	text += " \n"
	text += "Hint: Save mana to amplify the effect of this ability.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s base damage\n" % quillspray_damage_ratio_add
	text += "%s chance to doublecast Quillsprays at level 15\n" % double_chance
	text += "%s chance to triplecast Quillsprays at level 25\n" % triple_chance

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower releases thorns from its back, damaging every unit in range.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Quillspray", 800, TargetType.new(TargetType.CREEPS))]


func tower_init():
	thorns_bt = BuffType.new("thorns_bt", 0, 0, false, self)
	thorns_bt.set_buff_icon("res://Resources/Icons/GenericIcons/polar_star.tres")
	thorns_bt.set_buff_tooltip("Thorns\nIncreases attack damage taken when hit by Quillspray.")

	quillspray_pt = ProjectileType.create("QuillSprayMissile.mdl", 2, 1300, self)
	quillspray_pt.enable_homing(on_projectile_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Quillspray"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Icons/spears/many_spears_01.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = QUILLSPRAY_RANGE
	autocast.auto_range = 700
	autocast.cooldown = 0.2
	autocast.mana_cost = 5
	autocast.target_self = true
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = null
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var chance: float = _stats.occasional_quillspray_chance + _stats.occasional_quillspray_chance_add * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, null, "Occasional Quillspray")

	do_quillspray_series()


func on_autocast(_event: Event):
	do_quillspray_series()


func on_projectile_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var active_buff: Buff = creep.get_buff_of_type(thorns_bt)
	var buff_level: int
	if active_buff != null:
		buff_level = min(active_buff.get_level(), QUILLSPRAY_STACKS_MAX)
	else:
		buff_level = 0

	var damage_ratio: float = (QUILLSPRAY_DAMAGE_RATIO + QUILLSPRAY_DAMAGE_RATIO_ADD * tower.get_level()) * pow(1.0 + QUILLSPRAY_STACK_BONUS, buff_level)
	var damage: float = damage_ratio * tower.get_current_attack_damage_with_bonus()

	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())
	thorns_bt.apply_advanced(tower, creep, buff_level + 1, 0, QUILLSPRAY_DEBUFF_DURATION)


func do_quillspray_series():
	var level: int = tower.get_level()

	quillspray(1350)

	if level == 25:
		if tower.calc_chance(_stats.triple_chance):
			CombatLog.log_ability(tower, null, "Tripple Quillspray")
			quillspray(1500)
			quillspray(1700)
		else:
			CombatLog.log_ability(tower, null, "Double Quillspray")
			quillspray(1500)
	elif level > 15:
		if tower.calc_chance(_stats.double_chance):
			CombatLog.log_ability(tower, null, "Double Quillspray")
			quillspray(1500)


func quillspray(speed: float):
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), QUILLSPRAY_RANGE)

	while true:
		var creep: Unit = creeps_in_range.next()

		if creep == null:
			break

		var projectile: Projectile = Projectile.create_from_unit_to_unit(quillspray_pt, tower, 1.0, 1.0, tower, creep, true, false, false)
		projectile.set_projectile_scale(0.7)
		projectile._speed = speed
