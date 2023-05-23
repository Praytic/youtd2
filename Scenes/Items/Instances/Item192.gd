# Deep Shadows
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Deep Shadows[/color]\n"
	text += "Deals an additional 25% damage as spell damage against creeps with Sol armor."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func on_damage(event: Event):
	var itm: Item = self
	var T: Creep = event.get_target()
	var U: Tower = itm.get_carrier()

	if T.get_armor_type() == ArmorType.enm.SOL:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit("AvengerMissile.mdl", T, "chest")
