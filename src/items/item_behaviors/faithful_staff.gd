extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_spell_cast(event: Event):
	var tower: Unit = item.get_carrier()
	var target_unit: Unit = event.get_target()

	if target_unit is Tower:
		CombatLog.log_item_ability(item, null, "Reward the Faithful")
		
		target_unit.add_exp(1)
		tower.add_exp(1)
