extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {bug_dmg = 6, production_for_decrease = 12},
		2: {bug_dmg = 12, production_for_decrease = 10},
		3: {bug_dmg = 20, production_for_decrease = 8},
		4: {bug_dmg = 30, production_for_decrease = 6},
	}


func get_extra_tooltip_text() -> String:
	var bug_dmg: String = Utils.format_float(_stats.bug_dmg, 2)
	var production_for_decrease: String = Utils.format_float(_stats.production_for_decrease, 2)

	var text: String = ""

	text += "[color=GOLD]Swarm of Bugs[/color]\n"
	text += "On kill, produces bugs that increase the base damage of this tower by %s. The damage gain decreases by 1 for every %s productions, down to a minimum of 1.\n" % [bug_dmg, production_for_decrease]
	text += " \n"
	text += "Number of produced bugs is retained through upgrade and applied with the upgrade's values. Replacing a tower from a different family will produce bugs from 60% of its total kills.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	var tower: Tower = self
	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE, max(_stats.bug_dmg - tower.user_int / _stats.production_for_decrease, 1))
	tower.user_int = tower.user_int + 1


func on_create(preceding_tower: Tower):
	var tower: Tower = self
	var prev: Tower = preceding_tower
	var N: int
	var mults: int

	if prev != null:
		if prev.get_family() == tower.get_family():
			tower.user_int = prev.user_int
		else:
			tower.user_int = int(prev.get_kills() * 0.6)

		mults = tower.user_int / _stats.production_for_decrease

		if mults >= _stats.bug_dmg:
			mults = _stats.bug_dmg - 1

		N = mults * _stats.production_for_decrease
		N = int((_stats.bug_dmg + 0.5 - mults / 2.0) * N) + (tower.user_int - N) * (_stats.bug_dmg - mults)
		tower.modify_property(Modification.Type.MOD_DAMAGE_BASE, N)
	else:
		tower.user_int = 0
