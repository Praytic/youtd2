extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {chance_base = 0.008, chance_add = 0.0015},
		2: {chance_base = 0.010, chance_add = 0.0017},
		3: {chance_base = 0.012, chance_add = 0.0020},
		4: {chance_base = 0.014, chance_add = 0.0022},
		5: {chance_base = 0.016, chance_add = 0.0024},
		6: {chance_base = 0.020, chance_add = 0.0025},
	}


func get_extra_tooltip_text() -> String:
	var chance_base: String = String.num(_stats.chance_base * 100, 2)
	var chance_add: String = String.num(_stats.chance_add * 100, 2)

	var text: String = ""

	text += "[color=gold]Tomb's Curse[/color]\n"
	text += "This tower has a %s%% chance on attack to kill a non boss, non champion target immediately.\n" % chance_base
	text += "[color=orange]Level Bonus:[/color]\n"
	text += "+%s%% chance" % chance_add
	
	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", _stats.chance_base, _stats.chance_add)


func on_damage(event: Event):
	var tower = self

	var creep: Unit = event.get_target()
	var size: int = creep.get_size()

	if size < CreepSize.enm.CHAMPION:
		tower.kill_instantly(creep)
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
