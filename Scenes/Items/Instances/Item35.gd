# Bonk's Face
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Crush[/color]\n"
	text += "Whenever the carrier damages a stunned creep it deals 20% of its current attack damage as spelldamage in 250 AoE around its target.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.25, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self
	var creep: Unit = event.get_target()
	var twr: Unit = itm.get_carrier()
	var target_effect: int

	if creep.get_buff_of_group("stun") != null:
		twr.do_spell_damage_aoe_unit(creep, 250, twr.get_current_attack_damage_with_bonus() * 0.2, twr.calc_spell_crit_no_bonus(), 0)
		target_effect = Effect.create_scaled("ImpaleTargetDust.mdl", creep.get_visual_position().x, creep.get_visual_position().y, 0.0, 0, 2.0)
		Effect.set_lifetime(target_effect, 3.0)
