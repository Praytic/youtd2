extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.75, 0.01)


func on_attack(_event: Event):
	var tower: Tower = item.get_carrier()

	if tower.subtract_mana(0.05 * tower.get_overall_mana(), false) == 0:
		tower.order_stop()
