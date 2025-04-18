extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func periodic(_event: Event):
	CombatLog.log_item_ability(item, null, "Pay With Blood")
	item.get_carrier().remove_exp(2)
