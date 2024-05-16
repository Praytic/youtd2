extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]High Knowledge[/color]\n"
	text += "Whenever the carrier hits the main target, it gains 0.2 experience. The amount of experience gained is range and base attack speed adjusted.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = item.get_carrier()
	var cd: float = tower.get_base_attack_speed()
	var tower_range: float = tower.get_range()

	if event.is_main_target():
		tower.add_exp(0.2 * cd * (800 / tower_range))
