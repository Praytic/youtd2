extends Tower


# Original script has a typo. The third tier makes duration
# of goldrush buff increase by 1s per level instead of 0.1s.
# Decided to fix the typo.


var drol_goldrush: BuffType
var drol_excavation_multi: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {attackspeed_base = 0, attackspeed_divisor = 5, goldrush_gold = 1.0, goldrush_gold_add = 0.04, excavation_gold = 7.5, excavation_gold_add = 0.3},
		2: {attackspeed_base = 20, attackspeed_divisor = 3, goldrush_gold = 2.8, goldrush_gold_add = 0.1, excavation_gold = 21, excavation_gold_add = 0.8},
		3: {attackspeed_base = 40, attackspeed_divisor = 2, goldrush_gold = 5.4, goldrush_gold_add = 0.22, excavation_gold = 40, excavation_gold_add = 1.6},
	}


func get_extra_tooltip_text() -> String:
	var attackspeed_bonus: String = Utils.format_percent((_stats.attackspeed_base + 20) / 100.0, 2)
	var goldrush_gold: String = Utils.format_float(_stats.goldrush_gold, 2)
	var goldrush_gold_add: String = Utils.format_float(_stats.goldrush_gold_add, 2)
	var excavation_gold: String = Utils.format_float(_stats.excavation_gold, 2)
	var excavation_gold_add: String = Utils.format_float(_stats.excavation_gold_add, 2)

	var text: String = ""

	text += "[color=GOLD]Goldrush[/color]\n"
	text += "The miner has a 20%% chance on attack to go into a goldrush, increasing attackspeed by more than %s depending on the player's gold and making each hit gain %s gold. Goldrush lasts 5 seconds. Cannot retrigger while in goldrush!\n" % [attackspeed_bonus, goldrush_gold]
	text += " \n"
	text += "Hint: Check multiboard to view exact attack speed bonus\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s gold gained\n" % goldrush_gold_add
	text += "+0.1 seconds duration\n"
	text += " \n"
	text += "[color=GOLD]Excavation[/color]\n"
	text += "Every 20 seconds the miner has a 25%% chance to find %s gold.\n" % excavation_gold
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s gold\n" % excavation_gold_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 20)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.20, 0.008)


func tower_init():
	var m: Modifier = Modifier.new()
	drol_goldrush = BuffType.new("drol_goldrush", 5, 0.1, true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.2, 0.01)
	drol_goldrush.set_buff_icon("@@0@@")
	drol_goldrush.set_buff_modifier(m)
	drol_goldrush.set_stacking_group("drol_goldrush")
	drol_goldrush.set_buff_tooltip("Goldrush\nThis tower is affected by Goldrush; it has increased attackspeed and makes gold every time it attacks.")

	drol_excavation_multi = MultiboardValues.new(2)
	drol_excavation_multi.set_key(0, "Gold gained")
	drol_excavation_multi.set_key(1, "Goldrush bonus")


func on_attack(_event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.2):
		return

	if tower.get_buff_of_group("drol_goldrush") == null:
		var gold_amount: float = GoldControl.get_gold()
		drol_goldrush.apply_custom_timed(tower, tower, int(_stats.attackspeed_base + pow(gold_amount,0.5) / _stats.attackspeed_divisor), 5 + tower.get_level() * 0.1)


func on_damage(event: Event):
	var tower: Tower = self

	var gold_bonus = _stats.goldrush_gold + tower.get_level() * _stats.goldrush_gold_add

	if event.is_main_target() && tower.get_buff_of_group("drol_goldrush") != null:
		tower.user_real = tower.user_real + gold_bonus
		tower.get_player().give_gold(gold_bonus, tower, false, true)


func on_create(preceding: Tower):
	var tower: Tower = self

	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real = preceding.user_real
	else:
		tower.user_real = 0.0


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var gold_amount: float = GoldControl.get_gold()
	var excavation_value: int = 20 + int(pow(gold_amount, 0.5) / 5)

	drol_excavation_multi.set_value(0, str(int(tower.user_real)))
	drol_excavation_multi.set_value(1, str(excavation_value) + "%")

	return drol_excavation_multi


func periodic(_event: Event):
	var tower: Tower = self
	var gold_bonus: float = _stats.excavation_gold + tower.get_level() * _stats.excavation_gold_add

	var target_effect: int = Effect.create_scaled("AncientProtectorMissile.mdl", tower.get_x(), tower.get_y(), 0, 0, 0.8)
	Effect.set_lifetime(target_effect, 0.1)

	if tower.calc_chance(0.25):
		tower.user_real = tower.user_real + gold_bonus
		tower.get_player().give_gold(gold_bonus, tower, false, true)
