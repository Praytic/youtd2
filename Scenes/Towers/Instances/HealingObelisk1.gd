extends Tower

# NOTE: not a real tower script, used as a template for
# tower scripts.


func get_tier_stats() -> Dictionary:
	return {
		1: {heal_ratio = 0.50, heal_ratio_add = 0.0040},
		2: {heal_ratio = 0.55, heal_ratio_add = 0.0052},
		3: {heal_ratio = 0.60, heal_ratio_add = 0.0068},
		4: {heal_ratio = 0.65, heal_ratio_add = 0.0080},
	}


func get_extra_tooltip_text() -> String:
	var heal_ratio: String = Utils.format_percent(_stats.heal_ratio, 2)
	var heal_ratio_add: String = Utils.format_percent(_stats.heal_ratio_add, 2)

	var text: String = ""

	text += "[color=GOLD]Grace[/color]\n"
	text += "%s of the damage done by this tower will be revoked over 3 seconds. Does not affect immune targets.\n" % heal_ratio
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-%s of the damage healed\n" % heal_ratio_add
	text += "+1 second needed to heal at level 15 and 25\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_level_up(on_level_up)


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var loop_count: int = tower.user_int
	var healing: int = int(event.damage * (_stats.heal_ratio - tower.get_level() * _stats.heal_ratio_add))

	if !target.is_immune():
		healing = int(healing / loop_count)
		
		while true:
			if loop_count == 0:
				break

			await get_tree().create_timer(1.0).timeout

			if Utils.unit_is_valid(tower) && Utils.unit_is_valid(target):
				Unit.set_unit_state(target, Unit.State.LIFE, Unit.get_unit_state(target, Unit.State.LIFE) + healing)
				SFX.sfx_at_unit("HolyBoltSpecialArt.mdl", target)
				tower.get_player().display_floating_text_x("+" + str(healing), target, 0, 255, 0, 255, 0.05, 0.0, 2.0)
			else:
				return

			loop_count = loop_count - 1


func on_level_up(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()

	if level < 15:
		tower.user_int = 3
	elif level < 25:
		tower.user_int = 4
	else:
		tower.user_int = 5


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	var level: int = tower.get_level()

	if level < 15:
		tower.user_int = 3
	elif level < 25:
		tower.user_int = 4
	else:
		tower.user_int = 5
