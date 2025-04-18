extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if Utils.rand_chance(Globals.synced_rng, 0.10):
		CombatLog.log_item_ability(item, null, "Drunk!")
		item.get_carrier().get_player().display_small_floating_text(tr("FLOATING_TEXT_MISS"), item.get_carrier(), Color8(255, 0, 0), 40.0)
		event.damage = 0
