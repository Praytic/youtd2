extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Day/night mechanic is not
# implemented so this tower is disabled. Disabled by
# removing lines from tower props csv.


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


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	darkness_bt = BuffType.new("darkness_bt", 5, 0, true, self)
	darkness_bt.set_buff_icon("res://resources/icons/generic_icons/fire_dash.tres")
	darkness_bt.set_buff_tooltip("Engulfing Darkness\nPowerful as if it was night.")

#	NOTE: settubg damage to "1.0" here because value for
#	actual damage is passed when spell is casted as
#	"damage_ratio"
	swarm_st = SpellType.new(SpellType.Name.CARRION_SWARM, 3.0, self)
	swarm_st.data.swarm.damage = 1.0
	swarm_st.data.swarm.start_radius = SWARM_START_RADIUS
	swarm_st.data.swarm.end_radius = SWARM_END_RADIUS
	swarm_st.data.swarm.travel_distance = 1200
	swarm_st.data.swarm.effect_path = "res://src/effects/death_coil.tscn"


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
