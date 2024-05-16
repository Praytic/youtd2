extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Enlighten[/color]\n"
	text += "Whenever the carrier hits the main target, it has a 20% attack speed adjusted chance to make the target give 5% more experience. This modification is permanent and it stacks.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier() 
	var speed: float = tower.get_base_attack_speed()  

	if event.is_main_target() && tower.calc_chance(0.2 * speed) == true:
		CombatLog.log_item_ability(item, event.get_target(), "Enlighten")
		event.get_target().modify_property(Modification.Type.MOD_EXP_GRANTED, 0.05)
