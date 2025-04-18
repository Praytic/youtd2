extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 12)


func periodic(_event: Event):
	CombatLog.log_item_ability(item, null, "Learn")
	
	var tower: Unit = item.get_carrier()
	tower.add_exp(1)
