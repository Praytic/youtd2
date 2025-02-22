extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(on_periodic, 1.0)


func on_periodic(event: Event):
	var tower: Tower = item.get_carrier()
	var lvl: int = tower.get_level()
	event.enable_advanced(15 - lvl * 0.3, false)
	if tower.get_exp() >= 2.0:
		CombatLog.log_item_ability(item, null, "Exchange")
		tower.remove_exp_flat(2)
		tower.get_player().give_gold(7, tower, true, true)
	else:
		tower.get_player().display_floating_text("Not enough credits!", tower, Color8(255, 0, 0))
