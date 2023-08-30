# Pendant of Promptness
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Energy Drainer[/color]\n"
	text += "Attacking with super speed comes at a price. The carrier burns 5% of its maximum mana per attack. Without mana it is unable to attack.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.75, 0.01)


func on_attack(_event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if tower.subtract_mana(0.05 * tower.get_overall_mana(), false) == 0:
		tower.order_stop()
