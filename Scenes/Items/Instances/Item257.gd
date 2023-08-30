# Deep Shadows
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Shrapnel Munition[/color]\n"
	text += "Deals an additional 25% damage as spell damage against creeps with Lua armor."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var T: Creep = event.get_target()

	if T.get_armor_type() == ArmorType.enm.LUA:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit("FlyingMachineImpact.mdl", T, "chest")
