# Priest Figurine
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Enlighten[/color]\n"
	text += "Whenever the carrier of this item damages a creep there is a 20% attackspeed adjusted chance that the damaged creep grants 5% more experience. This modification is permanent and it stacks."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func on_damage(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if event.is_main_target() && tower.calc_chance(0.2 * speed) == true:
		event.get_target().modify_property(Modification.Type.MOD_EXP_GRANTED, 0.05)
