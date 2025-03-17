extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_add = 0.5},
		2: {mana_add = 0.6},
		3: {mana_add = 0.7},
		4: {mana_add = 0.8},
		5: {mana_add = 0.9},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Overheat"
	ability.icon = "res://resources/icons/orbs/orb_molten.tres"
	ability.description_short = "Attacks cost mana.\n"
	ability.description_full = "Each attack costs 1 mana, which is regenerated at a rate of 1 mana per second.\n"
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials_DELETEME(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, _stats.mana_add)


func on_attack(_event: Event):
	var mana: float = tower.get_mana()

	if mana < 1:
		tower.order_stop()
	else:
		tower.set_mana(mana - 1)
