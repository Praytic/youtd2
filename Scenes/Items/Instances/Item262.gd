# Granite Hammer
extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Heavy Weapon[/color]\n"
	text += "Every 5th attack is a critical hit.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()
	item.user_int = item.user_int + 1

	if item.user_int == 5:
		CombatLog.log_item_ability(item, null, "Heavy Weapon")
		
		tower.add_attack_crit()

		item.user_int = 0


func on_pickup():
	item.user_int = 1
