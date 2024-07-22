extends ItemBehavior


func get_ability_description() -> String:
	var myt_string: String = ArmorType.convert_to_colored_string(ArmorType.enm.MYT)

	var text: String = ""

	text += "[color=GOLD]Piercing Magic[/color]\n"
	text += "Increases attack damage against creeps with %s armor by 25%%.\n" % myt_string

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Creep = event.get_target()

	if target.get_armor_type() == ArmorType.enm.MYT:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit(SfxPaths.WATER_SLASH, target, Unit.BodyPart.CHEST)
