extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_base = 0.3},
		2: {miss_chance_base = 0.4},
		3: {miss_chance_base = 0.5},
		4: {miss_chance_base = 0.6},
		5: {miss_chance_base = 0.7},
	}


func get_ability_description() -> String:
	var miss_chance_base: String = Utils.format_percent(_stats.miss_chance_base, 2)

	var text: String = ""

	text += "[color=GOLD]Warming Up[/color]\n"
	text += "Each attack of this tower has a %s chance to miss the target.\n" % miss_chance_base
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.6% miss chance"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower = self

	if tower.calc_bad_chance(_stats.miss_chance_base - tower.get_level() * 0.006):
		event.damage = 0
		tower.get_player().display_floating_text_x("Miss", tower, 255, 0, 0, 255, 0.05, 0.0, 2.0)
