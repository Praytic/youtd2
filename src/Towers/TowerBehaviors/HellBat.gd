extends TowerBehavior


var darkness_bt: BuffType
var swarm_st: SpellType


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


func get_ability_info_list() -> Array[AbilityInfo]:
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

	var list: Array[AbilityInfo] = []
	
	var bat_swarm: AbilityInfo = AbilityInfo.new()
	bat_swarm.name = "Bat Swarm"
	bat_swarm.icon = "res://resources/icons/animals/bat_03.tres"
	bat_swarm.description_short = "This tower has a chance on attack to release a swarm of bats at the main target. The swarm deals spell damage in a cone.\n"
	bat_swarm.description_full = "This tower has a %s chance on attack to release a swarm of bats at the main target. The swarm deals %s spell damage at nighttime or %s spell damage at daytime to all enemies in a cone. The cone grows from a %s AoE radius at the start to a %s AoE radius at the end.\n" % [on_attack_chance, swarm_damage_night, swarm_damage_day, SWARM_START_RADIUS, SWARM_END_RADIUS] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % on_attack_chance_add \
	+ "+%s damage during night\n" % swarm_damage_night_add \
	+ "+%s damage during day\n" % swarm_damage_day_add
	list.append(bat_swarm)

	var creature: AbilityInfo = AbilityInfo.new()
	creature.name = "Creature of the Night"
	creature.icon = "res://resources/icons/animals/spider_03.tres"
	creature.description_short = "This tower deals more attack damage during nighttime.\n"
	creature.description_full = "This tower deals %s attack damage during nighttime and %s attack damage during daytime.\n" % [attack_damage_night, attack_damage_day] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage during night\n" % attack_damage_night_add \
	+ "+%s damage during day\n" % attack_damage_day_add
	list.append(creature)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	darkness_bt = BuffType.new("darkness_bt", 5, 0, true, self)
	darkness_bt.set_buff_icon("res://resources/icons/GenericIcons/fire_dash.tres")
	darkness_bt.set_buff_tooltip("Engulfing Darkness\nPowerful as if it was night.")

#	NOTE: settubg danage to "1.0" here because value for
#	actual damage is passed when spell is casted as
#	"damage_ratio"
	swarm_st = SpellType.new("@@0@@", "carrionswarm", 3.0, self)
	swarm_st.data.swarm.damage = 1.0
	swarm_st.data.swarm.start_radius = SWARM_START_RADIUS
	swarm_st.data.swarm.end_radius = SWARM_END_RADIUS


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var engulfing_darkness_duration: String = Utils.format_float(ENGULFING_DARKNESS_DURATION, 2)

	autocast.title = "Engulfing Darkness"
	autocast.icon = "res://resources/icons/orbs/orb_shadow.tres"
	autocast.description_short = "This tower engulfs itself in darkness, gaining power as if it's night.\n"
	autocast.description = "This tower engulfs itself in darkness, gaining power as if it's night for %s seconds.\n" % engulfing_darkness_duration
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
	autocast.buff_type = darkness_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast

	return [autocast]


func on_attack(event: Event):
	var level: int = tower.get_level()
	var target: Unit = event.get_target()
	var chance: float = ON_ATTACK_CHANCE + ON_ATTACK_CHANCE_ADD * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Bat Swarm")

	var damage_ratio: int
	if time_is_night():
		damage_ratio = _stats.swarm_damage_night + _stats.swarm_damage_night_add * level
	else:
		damage_ratio = _stats.swarm_damage_day + _stats.swarm_damage_day_add * level

	swarm_st.target_cast_from_caster(tower, target, damage_ratio, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var level: int = tower.get_level()
	var damage_ratio: float
	if time_is_night():
		damage_ratio = ATTACK_DAMAGE_NIGHT + _stats.attack_damage_night_add * level
	else:
		damage_ratio = ATTACK_DAMAGE_DAY + _stats.attack_damage_day_add * level

	event.damage *= damage_ratio


func on_autocast(_event: Event):
	darkness_bt.apply(tower, tower, tower.get_level())


func time_is_night() -> bool:
	var time: float = Utils.get_time_of_day()
	var out: bool = time >= 18.00 || time < 6.00 || tower.get_buff_of_type(darkness_bt) != null

	return out
