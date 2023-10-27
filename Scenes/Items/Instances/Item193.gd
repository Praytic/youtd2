# Staff of Essence
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Essence Attack[/color]\n"
	text += "The carrier of this item deals 100% damage against all armor types.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var AT: AttackType.enm = T.get_attack_type()
	var C: Creep = event.get_target()
	var r: float = AttackType.get_damage_against(AT, C.get_armor_type())

	if event.is_spell_damage() == false:
		event.damage = event.damage / r
