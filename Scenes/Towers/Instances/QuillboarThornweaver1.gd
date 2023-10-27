extends Tower


var sir_boar_proj: ProjectileType
var sir_boar_debuff: BuffType


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


func get_ability_description() -> String:
	var occasional_quillspray_chance: String = Utils.format_percent(_stats.occasional_quillspray_chance, 2)
	var occasional_quillspray_chance_add: String = Utils.format_percent(_stats.occasional_quillspray_chance_add, 2)

	var text: String = ""

	text += "[color=GOLD]Occasional Quillspray[/color]\n"
	text += "On attack this tower has a %s chance to trigger a Quillspray.\n" % occasional_quillspray_chance
	text += " \n"
	text += "Hint: This Quillspray costs no mana.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % occasional_quillspray_chance_add

	return text


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


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	sir_boar_debuff = BuffType.new("sir_boar_debuff", 0, 0, false, self)
	sir_boar_debuff.set_buff_icon("@@0@@")
	sir_boar_debuff.set_buff_tooltip("Thorns\nThis unit has been hit by a Quillspray; it will receive extra damage if it gets hit by another Quillspray.")

	sir_boar_proj = ProjectileType.create("QuillSprayMissile.mdl", 2, 1300, self)
	sir_boar_proj.enable_homing(on_projectile_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Quillspray"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
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
	add_autocast(autocast)


func on_attack(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var chance: float = _stats.occasional_quillspray_chance + _stats.occasional_quillspray_chance_add * level

	if !tower.calc_chance(chance):
		return

	do_quillspray_series()


func on_autocast(_event: Event):
	do_quillspray_series()


func on_projectile_hit(projectile: Projectile, creep: Unit):
	var tower: Tower = projectile.get_caster()
	var active_buff: Buff = creep.get_buff_of_type(sir_boar_debuff)
	var buff_level: int
	if active_buff != null:
		buff_level = min(active_buff.get_level(), QUILLSPRAY_STACKS_MAX)
	else:
		buff_level = 0

	var damage_ratio: float = (QUILLSPRAY_DAMAGE_RATIO + QUILLSPRAY_DAMAGE_RATIO_ADD * tower.get_level()) * pow(1.0 + QUILLSPRAY_STACK_BONUS, buff_level)
	var damage: float = damage_ratio * tower.get_current_attack_damage_with_bonus()

	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())
	sir_boar_debuff.apply_advanced(tower, creep, buff_level + 1, 0, QUILLSPRAY_DEBUFF_DURATION)


func do_quillspray_series():
	var tower: Tower = self
	var level: int = tower.get_level()

	quillspray(tower, 1350)

	if level == 25:
		if tower.calc_chance(_stats.triple_chance):
			quillspray(tower, 1500)
			quillspray(tower, 1700)
		else:
			quillspray(tower, 1500)
	elif level > 15:
		if tower.calc_chance(_stats.double_chance):
			quillspray(tower, 1500)


func quillspray(tower: Tower, speed: float):
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), QUILLSPRAY_RANGE)

	while true:
		var creep: Unit = creeps_in_range.next()

		if creep == null:
			break

		var projectile: Projectile = Projectile.create_from_unit_to_unit(sir_boar_proj, tower, 1.0, 1.0, tower, creep, true, false, false)
		projectile.setScale(0.7)
		projectile._speed = speed
