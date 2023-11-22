# Bones of Essence
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bones of Essence[/color]\n"
	text += "Increases the damage against creeps with the armor type sif by 25%.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Creep = event.get_target()

	if target.get_armor_type() == ArmorType.enm.SIF:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit("BansheeMissile.mdl", target, Unit.BodyPart.CHEST)
