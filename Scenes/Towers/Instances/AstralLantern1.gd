extends Tower

func get_tier_stats() -> Dictionary:
	return {
		1: {damage_base = 0.15, damage_add = 0.006},
		2: {damage_base = 0.20, damage_add = 0.008},
		3: {damage_base = 0.25, damage_add = 0.010},
		4: {damage_base = 0.30, damage_add = 0.012},
	}


func get_extra_tooltip_text() -> String:
	var damage_base: String = String.num(_stats.damage_base * 100, 2)
	var damage_add: String = String.num(_stats.damage_add * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Light in the Dark[/color]\n"
	text += "Deals %s%% additional damage to invisible creeps.\n" % damage_base
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s%% damage" % damage_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Unit = self

	if event.get_target().is_invisible():
		event.damage = event.damage * (_stats.damage_base * _stats.damage_add * tower.get_level())
