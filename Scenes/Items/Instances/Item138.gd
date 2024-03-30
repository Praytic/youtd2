# Bartuc's Spirit
extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bartuc's Spirit[/color]\n"
	text += "Every 10th attack will release a burst of magic doing 2000 spell damage to units in a range of 300 around the target.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+80 spell damage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	item.user_int = item.user_int + 1

	if item.user_int == 10:
		CombatLog.log_item_ability(item, event.get_target(), "Bartuc's Spirit")
		tower.do_spell_damage_aoe_unit(event.get_target(), 300, 2000 + (tower.get_level() * 80), tower.calc_spell_crit_no_bonus(), 0.0)
		SFX.sfx_at_unit("WarStompCaster.mdl", event.get_target())
		item.user_int = 0


func on_pickup():
	item.user_int = 0
