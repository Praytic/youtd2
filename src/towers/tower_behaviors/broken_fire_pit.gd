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


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var mod_crit_chance: String = Utils.format_percent(_stats.mod_crit_chance, 2)
	var mod_crit_chance_add: String = Utils.format_percent(MOD_CRIT_CHANCE_ADD, 2)
	var duration: String = Utils.format_float(_stats.duration, 2)
	var duration_add: String = Utils.format_float(DURATION_ADD, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Hot Coals"
	ability.icon = "res://resources/icons/fire/fire_bowl_02.tres"
	ability.description_short = "On kill, this tower gains increased crit chance.\n"
	ability.description_full = "On kill, this tower gains %s bonus crit chance for %s seconds.\n" % [mod_crit_chance, duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s sec duration\n" % duration_add \
	+ "+%s crit chance\n" % mod_crit_chance_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.mod_crit_chance, MOD_CRIT_CHANCE_ADD)
	coals_bt = BuffType.new("coals_bt ", _stats.duration, DURATION_ADD, true, self)
	coals_bt.set_buff_modifier(m)
	coals_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	coals_bt.set_buff_tooltip("Hot Coals\nIncreases critical chance.")


func on_kill(_event: Event):
	var level: int = tower.get_level()
	coals_bt.apply(tower, tower, level)
