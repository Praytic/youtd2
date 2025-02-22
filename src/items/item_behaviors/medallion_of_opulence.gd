extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier() 
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.2 * speed) == true:
		CombatLog.log_item_ability(item, event.get_target(), "Greed Is Good")
		tower.do_spell_damage(event.get_target(), item.get_player().get_gold() * (0.10), tower.calc_spell_crit_no_bonus())
