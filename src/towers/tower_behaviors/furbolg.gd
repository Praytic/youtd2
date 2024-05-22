extends TowerBehavior


var rage_0_bt: BuffType
var rage_15_bt: BuffType
var rage_25_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {trigger_chance = 0.14, buff_level = 0, buff_level_add = 2, duration = 4.0, duration_add = 0.08},
		2: {trigger_chance = 0.15, buff_level = 50, buff_level_add = 3, duration = 5.0, duration_add = 0.10},
		3: {trigger_chance = 0.16, buff_level = 100, buff_level_add = 4, duration = 6.0, duration_add = 0.12},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var trigger_chance: String = Utils.format_percent(_stats.trigger_chance, 2)
	var duration: String = Utils.format_float(_stats.duration, 2)
	var duration_add: String = Utils.format_float(_stats.duration_add, 2)
	var attack_speed: String = Utils.format_percent(1.5 + 0.01 * _stats.buff_level, 2)
	var attack_speed_add: String = Utils.format_percent(0.01 * _stats.buff_level_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Rampage"
	ability.icon = "res://resources/icons/misc/red_knight.tres"
	ability.description_short = "Whenever this tower attacks, it has a chance go into [color=GOLD]Rampage[/color], increasing attack speed and critical strike stats enormously.\n"
	ability.description_full = "Whenever this tower attacks, it has a %s chance to go into [color=GOLD]Rampage[/color] for %s seconds. While in [color=GOLD]Rampage[/color], the tower has +%s attack speed, +25%% critical strike chance and +75%% critical strike damage. Cannot retrigger while active!\n" % [trigger_chance, duration, attack_speed] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s sec duration\n" % duration_add \
	+ "+%s attack speed\n" % attack_speed_add \
	+ "+1 multicrit at lvl 15 and 25\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.20, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.01)
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	rage_0_bt = BuffType.new("rage_0_bt", 0, 0, true, self)
	rage_0_bt.set_buff_modifier(m)
	rage_0_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rage_0_bt.set_buff_tooltip("Rampage\nIncreases attack speed, crit chance and crit damage.")

	var m_15: Modifier = Modifier.new()
	m_15.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.0)
	m_15.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m_15.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	m_15.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	rage_15_bt = BuffType.new("rage_15_bt", 0, 0, true, self)
	rage_15_bt.set_buff_modifier(m_15)
	rage_15_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rage_15_bt.set_buff_tooltip("Rampage\nIncreases attack speed, crit chance, crit damage and multicrit.")

	var m_25: Modifier = Modifier.new()
	m_25.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.0)
	m_25.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m_25.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	m_25.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2.0, 0.0)
	rage_25_bt = BuffType.new("rage_25_bt", 0, 0, true, self)
	rage_25_bt.set_buff_modifier(m_25)
	rage_25_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rage_25_bt.set_buff_tooltip("Rampage\nIncreases attack speed, crit chance, crit damage and multicrit.")


func on_attack(_event: Event):
	if !tower.calc_chance(_stats.trigger_chance):
		return

	var lvl: int = tower.get_level()

#	Do not allow retriggering while the furbolg is enraged
	var is_enraged: bool = tower.get_buff_of_type(rage_0_bt) != null || tower.get_buff_of_type(rage_15_bt) != null || tower.get_buff_of_type(rage_25_bt) != null 

	if !is_enraged:
		CombatLog.log_ability(tower, null, "Rampage")

		var buff_type: BuffType
		if lvl < 15:
			buff_type = rage_0_bt
		elif lvl < 25:
			buff_type = rage_15_bt
		else:
			buff_type = rage_25_bt
		
		buff_type.apply_custom_timed(tower, tower, _stats.buff_level + lvl * _stats.buff_level_add, _stats.duration + _stats.duration_add * lvl)
