# Pendant of Mana Supremacy
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.38, 0.01)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 1.0, 0.01)


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Magical Greed[/color]\n"
	text += "When the carrier of this item casts a spell it has a 20% chance to replenish 15% of it's mana. This ability has 10 seconds cooldown.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% mana replenish\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_create():
	var itm: Item = self
	itm.user_int = 0


func on_spell_cast(event: Event):
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var t: Unit = T

	if !event.get_autocast_type().get_manacost() > 0.45:
#	  No cheating
		return

	if itm.user_int / 25 + 10.0 < Utils.get_game_time() / 25:
		if T.calc_chance(0.2):
			Unit.set_unit_state(t, Unit.State.MANA, Unit.get_unit_state(t, Unit.State.MANA) + Unit.get_unit_state(t, Unit.State.MAX_MANA) * (0.15 + T.get_level() * 0.006))
			var effect: int = Effect.create_simple_at_unit("ReplenishManaCasterOverhead.mdl", T)
			Effect.destroy(effect)
			itm.user_int = Utils.get_game_time()
