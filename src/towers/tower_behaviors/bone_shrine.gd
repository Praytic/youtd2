extends TowerBehavior


var curse_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_increase = 0.02, dmg_increase_add = 0.0004},
		2: {dmg_increase = 0.04, dmg_increase_add = 0.0008},
		3: {dmg_increase = 0.06, dmg_increase_add = 0.0012},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var dmg_increase: String = Utils.format_percent(_stats.dmg_increase, 2)
	var dmg_increase_add: String = Utils.format_percent(_stats.dmg_increase_add, 2)
	var darkness_string: String = Element.convert_to_colored_string(Element.enm.DARKNESS)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Empowering Darkness"
	ability.icon = "res://resources/icons/tower_variations/ash_geyser_purple.tres"
	ability.description_short = "Whenever this tower attacks, it makes the main target more vulnerable to %s.\n" % darkness_string
	ability.description_full = "Whenever this tower attacks, it increases the damage the main target receives from other %s towers by %s. This effect stacks up to 10 times.\n" % [darkness_string, dmg_increase] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ " +%s damage increased\n" % dmg_increase_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	curse_bt = BuffType.new("curse_bt", 0, 0, false, self)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	curse_bt.set_buff_tooltip("Curse of Shadow\nIncreases damage taken from Darkness towers.")


func on_attack(event: Event):
	var existing_buff: Buff = event.get_target().get_buff_of_type(curse_bt)
	var buff_level: int
	if existing_buff != null:
		buff_level = existing_buff.get_level()
	else:
		buff_level = 0 

	if buff_level < 10:
		event.get_target().modify_property(Modification.Type.MOD_DMG_FROM_DARKNESS, _stats.dmg_increase + tower.get_level() * _stats.dmg_increase_add)
		curse_bt.apply_advanced(tower, event.get_target(), buff_level + 1, 0, 1000)

	existing_buff = event.get_target().get_buff_of_type(curse_bt)
	if existing_buff != null:
		var stack_count: int = existing_buff.get_level()
		existing_buff.set_displayed_stacks(stack_count)