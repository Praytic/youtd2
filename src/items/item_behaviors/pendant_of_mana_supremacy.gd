extends ItemBehavior


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.38, 0.01)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 1.0, 0.01)


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magical Greed[/color]\n"
	text += "Whenever the carrier casts a spell, it has a 20% chance to replenish 15% of maximum mana. This ability has 10 seconds cooldown.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% mana replenish\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_create():
	item.user_int = 0


func on_spell_cast(event: Event):
	var T: Tower = item.get_carrier()
	var t: Unit = T

	if !event.get_autocast_type().get_manacost() > 0.45:
#	  No cheating
		return

	if item.user_int + 10.0 < Utils.get_time():
		if T.calc_chance(0.2):
			CombatLog.log_item_ability(item, null, "Magical Greed")

			t.set_mana(t.get_mana() + t.get_overall_mana() * (0.15 + T.get_level() * 0.006))
			var effect: int = Effect.create_simple_at_unit("res://src/effects/bdragon_334_falling_droplet.tscn", T)
			Effect.destroy_effect_after_its_over(effect)
			item.user_int = roundi(Utils.get_time())
