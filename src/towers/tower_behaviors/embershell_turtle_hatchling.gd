extends TowerBehavior


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var mana: float = tower.get_mana()

	if mana < 1:
		tower.order_stop()
	else:
		tower.set_mana(mana - 1)
