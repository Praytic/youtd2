extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	item.get_carrier().add_exp(1)
