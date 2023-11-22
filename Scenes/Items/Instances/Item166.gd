# Wand of Mana Zap
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Mana Zap[/color]\n"
	text += "The carrier's attacks zap away 8 mana from their target. Amount zapped is adjusted by attack speed and range.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6 mana\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	var creep: Creep = event.get_target()

	# var l: Lightning

	if event.is_main_target():
		if creep.subtract_mana((8 + 0.6 * tower.get_level() * tower.get_base_attack_speed()) * (55 / pow(tower.get_range(), 0.6)), true) > 0:
			var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, creep)
			lightning.modulate = Color.LIGHT_GREEN
			lightning.set_lifetime(0.1)
			SFX.sfx_on_unit("ArcaneTowerAttack.mdl", creep, Unit.BodyPart.ORIGIN)
