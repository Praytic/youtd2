# Magic Gloves
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Powers[/color]\n"
	text += "This item deals 100 spelldamage multiplied with the base attack speed of the tower on each attack.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+5 damage"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	tower.do_spell_damage(event.get_target(), (100 + (tower.get_level() * 5)) * tower.get_base_attack_speed(), tower.calc_spell_crit_no_bonus())
