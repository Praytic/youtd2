extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Essence Attack[/color]\n"
	text += "Carrier's attacks deal 100% attack damage against all armor types.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var T: Tower = item.get_carrier()
	var AT: AttackType.enm = T.get_attack_type()
	var C: Creep = event.get_target()
	var r: float = AttackType.get_damage_against(AT, C.get_armor_type())

#	NOTE: this check is actually not needed because DAMAGE
#	event is not called for spell damage
	if event.is_spell_damage() == false:
		event.damage = event.damage / r
