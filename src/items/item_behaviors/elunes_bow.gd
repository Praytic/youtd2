extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var dmg: float = item.get_carrier().get_current_attack_damage_base()

	if event.damage < dmg && event.is_main_target():
		event.damage = dmg
