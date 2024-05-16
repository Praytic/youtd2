extends TowerBehavior


var slow_bt: BuffType

func get_tier_stats() -> Dictionary:
	return {
	1: {slow_value = 0.15, chance = 0.15, chance_add = 0.0015},
	2: {slow_value = 0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = 0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = 0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = 0.27, chance = 0.18, chance_add = 0.0018},
}


func get_ability_info_list() -> Array[AbilityInfo]:
	var chance: String = Utils.format_percent(_stats.chance, 2)
	var chance_for_bosses: String = Utils.format_percent(_stats.chance * 2 / 3, 2)
	var slow_value: String = Utils.format_percent(_stats.slow_value, 2)
	var chance_add: String = Utils.format_percent(_stats.chance_add, 2)
	var chance_add_for_bosses: String = Utils.format_percent(_stats.chance_add * 2 / 3, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Atrophy"
	ability.icon = "res://resources/Icons/gloves/curse.tres"
	ability.description_short = "Whenever this tower attacks, it has a chance to slow the main target.\n"
	ability.description_full = "Whenever this tower attacks, it has a %s chance to slow the main target by %s for 5 seconds. Chance is reduced to %s for bosses.\n" % [chance, chance_for_bosses, slow_value] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s (%s for bosses) chance" % [chance_add, chance_add_for_bosses]
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	slow_bt.set_buff_icon("res://resources/Icons/GenericIcons/animal_skull.tres")
	slow_bt.set_buff_modifier(slow)
	slow_bt.set_stacking_group("slow_bt1")
	
	slow_bt.set_buff_tooltip("Atrophy\nReduces movement speed.")


func on_attack(event: Event):
	var creep: Unit = event.get_target()
	var size: int = creep.get_size()
	var calc: bool

	if size == CreepSize.enm.BOSS:
		calc = tower.calc_chance((_stats.chance + tower.get_level() * _stats.chance_add) * 2 / 3)
	else:
		calc = tower.calc_chance(_stats.chance + tower.get_level() * _stats.chance_add)

	if calc == true:
		CombatLog.log_ability(tower, creep, "Atrophy")

		slow_bt.apply_custom_timed(tower, event.get_target(), int(_stats.slow_value * 1000), 5.0)
