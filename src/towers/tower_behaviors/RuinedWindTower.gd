extends TowerBehavior


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Rejection"
	ability.icon = "res://resources/icons/clubs/club_01.tres"
	ability.description_short = "This tower drops all except Common items on attack.\n"
	ability.description_full = "This tower drops all except Common items on attack.\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var itm: Item
	var i: int = 1

	while true:
		if i > 6:
			break

		itm = tower.get_held_item(i)

		if itm != null && itm.get_rarity() != Rarity.enm.COMMON:
			itm.drop()
			itm.fly_to_stash(0.0)

		i = i + 1
