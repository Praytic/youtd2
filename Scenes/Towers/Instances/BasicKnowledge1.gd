extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {exp = 0.40},
		2: {exp = 0.55},
		3: {exp = 0.70},
		4: {exp = 0.85},
		5: {exp = 1.00},
	}


func get_extra_tooltip_text() -> String:
	var exp: String = Utils.format_float(_stats.exp, 2)

	var text: String = ""

	text += "[color=GOLD]High Knowledge[/color]\n"
	text += "Grants 0.7 experience on attack.\n" % exp

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(event: Event):
	var tower: Tower = self
	tower.add_exp(_stats.exp)
