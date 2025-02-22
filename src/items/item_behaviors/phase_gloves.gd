extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var damage: float = event.damage
	var creep: Unit = event.get_target()
	var tower: Tower = item.get_carrier()

	event.damage = damage * 0.7
	tower.do_spell_damage(creep, damage * 0.3, tower.calc_spell_crit_no_bonus())
