# Bartuc's Spirit
extends Item


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
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	itm.user_int = itm.user_int + 1

	if itm.user_int == 10:
		tower.do_spell_damage_aoe_unit(event.get_target(), 300, 2000 + (tower.get_level() * 80), tower.calc_spell_crit_no_bonus(), 0.0)
		SFX.sfx_at_unit("WarStompCaster.mdl", event.get_target())
		itm.user_int = 0


func on_pickup():
	var itm: Item = self
	itm.user_int = 0
