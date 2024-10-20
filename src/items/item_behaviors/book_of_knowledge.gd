extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()
	var cd: float = tower.get_base_attack_speed()
	var tower_range: float = tower.get_base_range()

	if event.is_main_target():
		tower.add_exp(0.2 * cd * (800 / tower_range))
