extends Tower


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Rejection[/color]\n"
	text += "This tower drops all except Common items on attack.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var tower: Tower = self

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
