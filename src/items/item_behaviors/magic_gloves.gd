extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	tower.do_spell_damage(event.get_target(), (100 + (tower.get_level() * 5)) * tower.get_base_attack_speed(), tower.calc_spell_crit_no_bonus())
