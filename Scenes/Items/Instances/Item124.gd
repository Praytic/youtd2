# Scroll of Piercing Magic
extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Piercing Magic[/color]\n"
	text += "Deals an additional 25% damage as spell damage against creeps with Sif armor.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var t: Creep = event.get_target()

	if t.get_armor_type() == ArmorType.enm.SIF:
		item.get_carrier().do_spell_damage(t, event.damage * 0.25, item.get_carrier().calc_spell_crit_no_bonus())
		SFX.sfx_on_unit("SpellBreakerAttack.mdl", t, Unit.BodyPart.ORIGIN)
