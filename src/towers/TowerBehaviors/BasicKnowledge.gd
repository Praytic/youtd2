extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {exp = 0.40},
		2: {exp = 0.55},
		3: {exp = 0.70},
		4: {exp = 0.85},
		5: {exp = 1.00},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var experience: String = Utils.format_float(_stats.exp, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "High Knowledge"
	ability.icon = "res://resources/icons/books/book_07.tres"
	ability.description_short = "Grants minor amount of experience on attack.\n"
	ability.description_full = "Grants %s experience on attack.\n" % experience
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	tower.add_exp(_stats.exp)
