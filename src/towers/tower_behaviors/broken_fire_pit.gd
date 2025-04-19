extends TowerBehavior


var coals_bt : BuffType


const MOD_CRIT_CHANCE_ADD: float = 0.003
const DURATION_ADD: float = 0.05


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_crit_chance = 0.15, duration = 7.5},
		2: {mod_crit_chance = 0.20, duration = 8.5},
		3: {mod_crit_chance = 0.25, duration = 9.5},
		4: {mod_crit_chance = 0.30, duration = 10.5},
		5: {mod_crit_chance = 0.35, duration = 11.5},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, _stats.mod_crit_chance, MOD_CRIT_CHANCE_ADD)
	coals_bt = BuffType.new("coals_bt ", _stats.duration, DURATION_ADD, true, self)
	coals_bt.set_buff_modifier(m)
	coals_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	coals_bt.set_buff_tooltip(tr("BB66"))


func on_kill(_event: Event):
	var level: int = tower.get_level()
	coals_bt.apply(tower, tower, level)
