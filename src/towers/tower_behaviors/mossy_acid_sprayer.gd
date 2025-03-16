extends TowerBehavior


var acid_bt: BuffType

# NOTE: values here are pre-multiplied by 1000, so 600 = 0.6
# as final value. That's how it is in original script and we
# stick to original to avoid introducting bugs.
func get_tier_stats() -> Dictionary:
	return {
		1: {armor_base = 0.6, armor_add = 0.024},
		2: {armor_base = 1.2, armor_add = 0.048},
		3: {armor_base = 2.4, armor_add = 0.096},
		4: {armor_base = 4.8, armor_add = 0.192},
		5: {armor_base = 9.6, armor_add = 0.384},
	}


const DEBUFF_DURATION: float = 3.0
const DEBUFF_DURATION_ADD: float = 0.12


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var debuff_duration: String = Utils.format_float(DEBUFF_DURATION, 2)
	var debuff_duration_add: String = Utils.format_float(DEBUFF_DURATION_ADD, 2)
	var armor_base: String = Utils.format_float(_stats.armor_base, 3)
	var armor_add: String = Utils.format_float(_stats.armor_add, 3)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Acid Coating"
	ability.icon = "res://resources/icons/potions/potion_green_03.tres"
	ability.description_short = "Decreases armor of hit creeps.\n"
	ability.description_full = "Decreases armor of hit creeps by %s for %s seconds.\n" % [armor_base, debuff_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s armor reduction\n" % armor_add \
	+ "+%s seconds\n" % debuff_duration_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(3, 0.15)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ARMOR, -_stats.armor_base, -_stats.armor_add)
	acid_bt = BuffType.new("acid_bt", DEBUFF_DURATION, DEBUFF_DURATION_ADD, false, self)
	acid_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	acid_bt.set_buff_modifier(m)

	acid_bt.set_buff_tooltip("Acid Corosion\nReduces armor.")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	acid_bt.apply(tower, target, level)
