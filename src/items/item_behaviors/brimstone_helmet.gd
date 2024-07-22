extends ItemBehavior


func get_ability_description() -> String:
	var elemental_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)
	
	var text: String = ""

	text += "[color=GOLD]Breath of Fire[/color]\n"
	text += "On attack, this item can change the carrier's attack type to %s at the cost of 100 charges. Regenerates 50 charges per attack. This effect is not visible on the tower itself.\n" % elemental_string
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 charge regenerated\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func on_attack(_event: Event):
	item.user_real = item.user_real + 50.0 + 1.0 * item.get_carrier().get_level()
	item.set_charges(int(item.user_real))


func on_damage(event: Event):
	var T: Tower = item.get_carrier()
	var C: Creep = event.get_target()

	if item.user_real >= 100.0:
		event.damage = event.damage / AttackType.get_damage_against(T.get_attack_type(), C.get_armor_type()) * AttackType.get_damage_against(AttackType.enm.ELEMENTAL, C.get_armor_type())
		SFX.sfx_on_unit(SfxPaths.FIRE_BALL, C, Unit.BodyPart.CHEST)
		item.user_real = item.user_real - 100.0
		item.set_charges(int(item.user_real))


func on_pickup():
	item.user_real = 0.0
	item.set_charges(0)
