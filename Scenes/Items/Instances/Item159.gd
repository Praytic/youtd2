# Charged Disk
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Power Supply[/color]\n"
	text += "The carrier deals 8% of its goldcost as spelldamage per attack. This amount is attackspeed adjusted.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% goldcost as spelldamage\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self

	var twr: Tower = itm.get_carrier() 

	if event.is_main_target():
		twr.do_spell_damage(event.get_target(), (0.08 + 0.001 * twr.get_level()) * twr.get_gold_cost() * twr.get_base_attack_speed(), twr.calc_spell_crit_no_bonus())
