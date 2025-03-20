extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {item_rarity = Rarity.enm.COMMON},
		2: {item_rarity = Rarity.enm.UNCOMMON},
		3: {item_rarity = Rarity.enm.RARE},
		4: {item_rarity = Rarity.enm.UNIQUE},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var itm: Item
	var i: int = 1

	var item_rarity: Rarity.enm = _stats.item_rarity

	while true:
		if i > 6:
			break

		itm = tower.get_held_item(i)

		if itm != null && itm.get_rarity() != item_rarity:
			itm.drop()
			itm.fly_to_stash(0.0)

		i = i + 1
