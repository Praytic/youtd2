extends TowerBehavior


# [ORIGINAL_GAME_BUG] Fixed Goldrush duration for tier
# 3 tower. +1sec/lvl => +0.1sec/lvl - how it is in ability
# description.


var goldrush_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {attack_speed_base = 0, attack_speed_divisor = 5, goldrush_gold = 1.0, goldrush_gold_add = 0.04, excavation_gold = 7.5, excavation_gold_add = 0.3},
		2: {attack_speed_base = 20, attack_speed_divisor = 3, goldrush_gold = 2.8, goldrush_gold_add = 0.1, excavation_gold = 21, excavation_gold_add = 0.8},
		3: {attack_speed_base = 40, attack_speed_divisor = 2, goldrush_gold = 5.4, goldrush_gold_add = 0.22, excavation_gold = 40, excavation_gold_add = 1.6},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 20)



func tower_init():
	var m: Modifier = Modifier.new()
	goldrush_bt = BuffType.new("goldrush_bt", 5, 0.1, true, self)
	m.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.2, 0.01)
	goldrush_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	goldrush_bt.set_buff_modifier(m)
	goldrush_bt.set_buff_tooltip(tr("AXB0"))

	multiboard = MultiboardValues.new(2)
	var gold_gained_label: String = tr("EX70")
	var goldrush_bonus_label: String = tr("RZJV")
	multiboard.set_key(0, gold_gained_label)
	multiboard.set_key(1, goldrush_bonus_label)


func on_attack(_event: Event):
	if !tower.calc_chance(0.2):
		return

	if tower.get_buff_of_type(goldrush_bt) == null:
		CombatLog.log_ability(tower, null, "Goldrush")

		var gold_amount: float = tower.get_player().get_gold()
		goldrush_bt.apply_custom_timed(tower, tower, int(_stats.attack_speed_base + pow(gold_amount,0.5) / _stats.attack_speed_divisor), 5 + tower.get_level() * 0.1)


func on_damage(event: Event):
	var gold_bonus = _stats.goldrush_gold + tower.get_level() * _stats.goldrush_gold_add

	if event.is_main_target() && tower.get_buff_of_type(goldrush_bt) != null:
		tower.user_real = tower.user_real + gold_bonus
		tower.get_player().give_gold(gold_bonus, tower, false, true)


func on_create(preceding: Tower):
	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real = preceding.user_real
	else:
		tower.user_real = 0.0


func on_tower_details() -> MultiboardValues:
	var gold_amount: float = tower.get_player().get_gold()
	var excavation_value: int = 20 + int(pow(gold_amount, 0.5) / 5)
	var gold_gained_text: String = Utils.format_float(tower.user_real, 2)
	var goldrush_bonus_text: String = "%d%%" % excavation_value

	multiboard.set_value(0, gold_gained_text)
	multiboard.set_value(1, goldrush_bonus_text)

	return multiboard


func periodic(_event: Event):
	var gold_bonus: float = _stats.excavation_gold + tower.get_level() * _stats.excavation_gold_add

	Effect.create_scaled("res://src/effects/ancient_protector_missile.tscn", tower.get_position_wc3(), 0, 2)

	if tower.calc_chance(0.25):
		CombatLog.log_ability(tower, null, "Excavation")

		tower.user_real = tower.user_real + gold_bonus
		tower.get_player().give_gold(gold_bonus, tower, false, true)
	else:
		CombatLog.log_ability(tower, null, "Excavation Fail")
