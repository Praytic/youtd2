extends Tower


var dave_darkness: BuffType
var dave_bats_st: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {swarm_damage_night = 600, swarm_damage_night_add = 15, swarm_damage_day = 200, swarm_damage_day_add = 5, attack_damage_night_add = 0.004, attack_damage_day_add = 0.002},
		2: {swarm_damage_night = 1650, swarm_damage_night_add = 45, swarm_damage_day = 550, swarm_damage_day_add = 15, attack_damage_night_add = 0.006, attack_damage_day_add = 0.003},
		3: {swarm_damage_night = 2700, swarm_damage_night_add = 90, swarm_damage_day = 900, swarm_damage_day_add = 30, attack_damage_night_add = 0.008, attack_damage_day_add = 0.004},
	}

const ON_ATTACK_CHANCE: float = 0.15
const ON_ATTACK_CHANCE_ADD: float = 0.002
const ENGULFING_DARKNESS_DURATION: float = 5.0
const ATTACK_DAMAGE_NIGHT: float = 1.5
const ATTACK_DAMAGE_DAY: float = 0.5
const SWARM_START_RADIUS: float = 100
const SWARM_END_RADIUS: float = 300


func get_ability_description() -> String:
	var on_attack_chance: String = Utils.format_percent(ON_ATTACK_CHANCE, 2)
	var on_attack_chance_add: String = Utils.format_percent(ON_ATTACK_CHANCE_ADD, 2)
	var swarm_damage_night: String = Utils.format_float(_stats.swarm_damage_night, 2)
	var swarm_damage_night_add: String = Utils.format_float(_stats.swarm_damage_night_add, 2)
	var swarm_damage_day: String = Utils.format_float(_stats.swarm_damage_day, 2)
	var swarm_damage_day_add: String = Utils.format_float(_stats.swarm_damage_day_add, 2)
	var attack_damage_night: String = Utils.format_percent(ATTACK_DAMAGE_NIGHT, 2)
	var attack_damage_night_add: String = Utils.format_percent(_stats.attack_damage_night_add, 2)
	var attack_damage_day: String = Utils.format_percent(ATTACK_DAMAGE_DAY, 2)
	var attack_damage_day_add: String = Utils.format_percent(_stats.attack_damage_day_add, 2)

	var text: String = ""

	text += "[color=GOLD]Bat Swarm[/color]\n"
	text += "This tower has a %s chance on attack to release a swarm of bats, dealing %s spell damage at nighttime or %s spell damage at daytime to all enemies in a cone. The cone grows from a %s AoE radius at the start to a %s AoE radius at the end.\n" % [on_attack_chance, swarm_damage_night, swarm_damage_day, SWARM_START_RADIUS, SWARM_END_RADIUS]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % on_attack_chance_add
	text += "+%s damage during night\n" % swarm_damage_night_add
	text += "+%s damage during day\n" % swarm_damage_day_add
	text += " \n"
	text += "[color=GOLD]Creature of the Night[/color]\n"
	text += "This tower deals %s damage during nighttime and %s damage during daytime.\n" % [attack_damage_night, attack_damage_day]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage during night\n" % attack_damage_night_add
	text += "+%s damage during day\n" % attack_damage_day_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Bat Swarm[/color]\n"
	text += "This tower has a chance on attack to release a swarm of bats.\n"
	text += " \n"
	text += "[color=GOLD]Creature of the Night[/color]\n"
	text += "This tower deals more damage during nighttime.\n"

	return text


func get_autocast_description() -> String:
	var engulfing_darkness_duration: String = Utils.format_float(ENGULFING_DARKNESS_DURATION, 2)

	var text: String = ""

	text += "This tower engulfs itself in darkness, gaining power as if it's night for %s seconds.\n" % engulfing_darkness_duration

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower engulfs itself in darkness, gaining power as if it's night.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	dave_darkness = BuffType.new("dave_darkness", 5, 0, true, self)
	dave_darkness.set_buff_icon("@@2@@")
	dave_darkness.set_buff_tooltip("Engulfing Darkness\nThis tower is affected by Engulfing Darkness; it is more powerful as if it's night.")

#	NOTE: settubg danage to "1.0" here because value for
#	actual damage is passed when spell is casted as
#	"damage_ratio"
	dave_bats_st = SpellType.new("@@0@@", "carrionswarm", 3.0, self)
	dave_bats_st.data.swarm.damage = 1.0
	dave_bats_st.data.swarm.start_radius = SWARM_START_RADIUS
	dave_bats_st.data.swarm.end_radius = SWARM_END_RADIUS

	var autocast: Autocast = Autocast.make()
	autocast.title = "Engulfing Darkness"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "AnimateDeadTarget.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 0
	autocast.auto_range = 0
	autocast.cooldown = 6
	autocast.mana_cost = 45
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = dave_darkness
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_attack(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var chance: float = ON_ATTACK_CHANCE + ON_ATTACK_CHANCE_ADD * level

	if !tower.calc_chance(chance):
		return

	var damage_ratio: int
	if time_is_night():
		damage_ratio = _stats.swarm_damage_night + _stats.swarm_damage_night_add * level
	else:
		damage_ratio = _stats.swarm_damage_day + _stats.swarm_damage_day_add * level

	dave_bats_st.target_cast_from_caster(tower, event.get_target(), damage_ratio, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var damage_ratio: float
	if time_is_night():
		damage_ratio = ATTACK_DAMAGE_NIGHT + _stats.attack_damage_night_add * level
	else:
		damage_ratio = ATTACK_DAMAGE_DAY + _stats.attack_damage_day_add * level

	event.damage *= damage_ratio


func on_autocast(_event: Event):
	var tower: Tower = self
	dave_darkness.apply(tower, tower, tower.get_level())


func time_is_night() -> bool:
	var tower: Tower = self
	var time: float = Utils.get_time_of_day()
	var out: bool = time >= 18.00 || time < 6.00 || tower.get_buff_of_type(dave_darkness) != null

	return out
