extends TowerBehavior


var roots_bt: BuffType
var stun_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {stun_chance = 0.05, slow_chance = 0.10, slow_duration = 7.5},
		2: {stun_chance = 0.06, slow_chance = 0.15, slow_duration = 8.5},
		3: {stun_chance = 0.07, slow_chance = 0.20, slow_duration = 9.5},
	}


const STUN_CHANCE_ADD: float = 0.001
const STUN_DURATION: float = 1.75
const STUN_DURATION_ADD: float = 0.05
const SLOW_AMOUNT: float = 0.15
const SLOW_CHANCE_ADD: float = 0.001
const SLOW_DURATION_ADD: float = 0.2


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_level_up(on_level_up)


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -SLOW_AMOUNT, 0.0)
	roots_bt = BuffType.new("roots_bt", 0, 0, false, self)
	roots_bt.set_buff_icon("res://resources/icons/generic_icons/root_tip.tres")
	roots_bt.set_buff_modifier(mod)
	roots_bt.set_buff_tooltip(tr("FDSR"))

	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)


func on_damage(event: Event):
	var level: int = tower.get_level()
	var creep: Unit = event.get_target()
	var slow_duration: float = _stats.slow_duration + SLOW_DURATION_ADD * level
	var slow_level: int = int(slow_duration * 1000)

	if tower.calc_chance(_stats.stun_chance + STUN_CHANCE_ADD * level):
		CombatLog.log_ability(tower, creep, "Gift of the Forest Stun")

		stun_bt.apply_only_timed(tower, creep, STUN_DURATION + STUN_DURATION_ADD * level)
	elif tower.calc_chance(_stats.slow_chance + SLOW_CHANCE_ADD * level):
		CombatLog.log_ability(tower, creep, "Gift of the Forest Slow")

		roots_bt.apply_custom_timed(tower, creep, slow_level, slow_duration)


func on_level_up(_event: Event):
	if tower.get_level() == 15:
		tower.set_target_count(4)


func on_create(_preceding: Tower):
	if tower.get_level() >= 15:
		tower.set_target_count(4)
