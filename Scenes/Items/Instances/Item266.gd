# Elunes Bow
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Elune's Grace[/color]\n"
	text += "Damage dealt to the main target of each attack cannot be reduced below the tower's base damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var dmg: float = itm.get_carrier().get_current_attack_damage_base()

	if event.damage < dmg && event.is_main_target():
		event.damage = dmg
