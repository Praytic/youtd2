extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {bonus_7 = 1.10, bonus_8 = 1.20, bonus_9 = 1.30, bonus_10 = 1.40, bonus_7_add = 0.002, bonus_8_add = 0.004, bonus_9_add = 0.006, bonus_10_add = 0.008},
		2: {bonus_7 = 1.10, bonus_8 = 1.20, bonus_9 = 1.30, bonus_10 = 1.40, bonus_7_add = 0.002, bonus_8_add = 0.004, bonus_9_add = 0.006, bonus_10_add = 0.008},
		3: {bonus_7 = 1.125, bonus_8 = 1.25, bonus_9 = 1.375, bonus_10 = 1.50, bonus_7_add = 0.0025, bonus_8_add = 0.005, bonus_9_add = 0.0075, bonus_10_add = 0.01},
		4: {bonus_7 = 1.125, bonus_8 = 1.25, bonus_9 = 1.375, bonus_10 = 1.50, bonus_7_add = 0.0025, bonus_8_add = 0.005, bonus_9_add = 0.0075, bonus_10_add = 0.01},
		5: {bonus_7 = 1.15, bonus_8 = 1.30, bonus_9 = 1.45, bonus_10 = 1.60, bonus_7_add = 0.003, bonus_8_add = 0.006, bonus_9_add = 0.009, bonus_10_add = 0.012},
		6: {bonus_7 = 1.15, bonus_8 = 1.30, bonus_9 = 1.45, bonus_10 = 1.60, bonus_7_add = 0.003, bonus_8_add = 0.006, bonus_9_add = 0.009, bonus_10_add = 0.012},
	}


func get_extra_tooltip_text() -> String:
	var bonus_7: String = String.num((_stats.bonus_7 - 1.0) * 100, 2)
	var bonus_8: String = String.num((_stats.bonus_8 - 1.0) * 100, 2)
	var bonus_9: String = String.num((_stats.bonus_9 - 1.0) * 100, 2)
	var bonus_10: String = String.num((_stats.bonus_10 - 1.0) * 100, 2)

	var bonus_7_add: String = String.num((_stats.bonus_7_add) * 100, 2)
	var bonus_8_add: String = String.num((_stats.bonus_8_add) * 100, 2)
	var bonus_9_add: String = String.num((_stats.bonus_9_add) * 100, 2)
	var bonus_10_add: String = String.num((_stats.bonus_10_add) * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Fireblossom[/color]\n"
	text += "Every 7th attack deals %s%% bonus damage.\n" % bonus_7
	text += "Every 8th attack deals %s%% bonus damage.\n" % bonus_8
	text += "Every 9th attack deals %s%% bonus damage.\n" % bonus_9
	text += "Every 10th attack deals %s%% bonus damage.\n" % bonus_10
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s%% bonus damage every 7th attack.\n" % bonus_7_add
	text += "+%s%% bonus damage every 8th attack.\n" % bonus_8_add
	text += "+%s%% bonus damage every 9th attack.\n" % bonus_9_add
	text += "+%s%% bonus damage every 10th attack." % bonus_10_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_create(_preceding_tower: Tower):
	var tower = self
	tower.user_int = 0
	tower.user_int2 = 0
	tower.user_int3 = 0
	tower.user_real = 0


func on_damage(event: Event):
	var tower = self

	var damage: float = event.damage
	var level: int = tower.get_level()

	tower.user_int = tower.user_int + 1
	tower.user_int2 = tower.user_int2 + 1
	tower.user_int3 = tower.user_int3 + 1
	tower.user_real = tower.user_real + 1

	if tower.user_int >= 7:
		event.damage = event.damage * (_stats.bonus_7 + level * _stats.bonus_7_add)
		tower.user_int = 0

	if tower.user_int2 >= 8:
		event.damage = event.damage * (_stats.bonus_8 + level * _stats.bonus_8_add)
		tower.user_int2 = 0

	if tower.user_int3 >= 9:
		event.damage = event.damage * (_stats.bonus_9 + level * _stats.bonus_9_add)
		tower.user_int3 = 0

	if tower.user_real >= 10:
		event.damage = event.damage * (_stats.bonus_10 + level * _stats.bonus_10_add)
		tower.user_real = 0

	if event.damage > damage:
		tower.get_player().display_small_floating_text(str(int(event.damage)), tower, 255, 150, 150, 0)
