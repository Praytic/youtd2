extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_create():
	item.user_int = 0


func on_spell_cast(event: Event):
	var T: Tower = item.get_carrier()
	var t: Unit = T

	if !event.get_autocast_type().get_mana_cost() > 0.45:
#	  No cheating
		return

	if item.user_int + 10.0 < Utils.get_time():
		if T.calc_chance(0.2):
			CombatLog.log_item_ability(item, null, "Magical Greed")

			t.set_mana(t.get_mana() + t.get_overall_mana() * (0.15 + T.get_level() * 0.006))
			Effect.create_simple_at_unit("res://src/effects/replenish_mana.tscn", T)
			item.user_int = roundi(Utils.get_time())
