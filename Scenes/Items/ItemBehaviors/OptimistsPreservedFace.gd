extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Optimist Hunting Season[/color]\n"
	text += "Changes attack damage based on the amount of health the creep has left. The range goes from +75% damage when the creep has full health to -50% damage when the creep has no health left.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var health_ratio: float = target.get_health() / target.get_overall_health()
	event.damage = event.damage * (1.75 - (1.25 * (1 - health_ratio)))
