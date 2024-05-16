extends TowerBehavior


# Original script has a typo. The third tier makes duration
# of goldrush buff increase by 1s per level instead of 0.1s.
# Decided to fix the typo.


var goldrush_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {attack_speed_base = 0, attack_speed_divisor = 5, goldrush_gold = 1.0, goldrush_gold_add = 0.04, excavation_gold = 7.5, excavation_gold_add = 0.3},
		2: {attack_speed_base = 20, attack_speed_divisor = 3, goldrush_gold = 2.8, goldrush_gold_add = 0.1, excavation_gold = 21, excavation_gold_add = 0.8},
		3: {attack_speed_base = 40, attack_speed_divisor = 2, goldrush_gold = 5.4, goldrush_gold_add = 0.22, excavation_gold = 40, excavation_gold_add = 1.6},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var attack_speed_bonus: String = Utils.format_percent((_stats.attack_speed_base + 20) / 100.0, 2)
	var goldrush_gold: String = Utils.format_float(_stats.goldrush_gold, 2)
	var goldrush_gold_add: String = Utils.format_float(_stats.goldrush_gold_add, 2)
	var excavation_gold: String = Utils.format_float(_stats.excavation_gold, 2)
	var excavation_gold_add: String = Utils.format_float(_stats.excavation_gold_add, 2)

	var list: Array[AbilityInfo] = []
	
	var goldrush: AbilityInfo = AbilityInfo.new()
	goldrush.name = "Goldrush"
	goldrush.icon = "res://resources/Icons/gems/gem_01.tres"
	goldrush.description_short = "The miner has a chance on attack to go into a [color=GOLD]Goldrush[/color]. [color=GOLD]Goldrush[/color] increases attack speed and grants gold whenever this tower hits a creep.\n"
	goldrush.description_full = "The miner has a 20%% chance on attack to go into a [color=GOLD]Goldrush[/color]. [color=GOLD]Goldrush[/color] increases attack speed by more than %s depending on the player's gold and grants %s gold whenever this tower hits a creep. Goldrush lasts 5 seconds. Cannot retrigger while active!\n" % [attack_speed_bonus, goldrush_gold] \
	+ " \n" \
	+ "Hint: Check multiboard to view exact attack speed bonus\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s gold gained\n" % goldrush_gold_add \
	+ "+0.1 seconds duration\n"
	list.append(goldrush)

	var excavation: AbilityInfo = AbilityInfo.new()
	excavation.name = "Excavation"
	excavation.icon = "res://resources/Icons/misc/gold_cart.tres"
	excavation.description_short = "Every few seconds the miner has a chance to find gold.\n"
	excavation.description_full = "Every 20 seconds the miner has a 25%% chance to find %s gold.\n" % excavation_gold \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s gold\n" % excavation_gold_add
	list.append(excavation)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 20)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.20, 0.008)


func tower_init():
	var m: Modifier = Modifier.new()
	goldrush_bt = BuffType.new("goldrush_bt", 5, 0.1, true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.2, 0.01)
	goldrush_bt.set_buff_icon("res://resources/Icons/GenericIcons/gold_bar.tres")
	goldrush_bt.set_buff_modifier(m)
	goldrush_bt.set_stacking_group("goldrush_bt")
	goldrush_bt.set_buff_tooltip("Goldrush\nIncreases attack speed and gives gold every time tower attacks.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Gold gained")
	multiboard.set_key(1, "Goldrush bonus")


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

	var target_effect: int = Effect.create_scaled("AncientProtectorMissile.mdl", tower.get_position_wc3(), 0, 5)
	Effect.set_lifetime(target_effect, 0.1)

	if tower.calc_chance(0.25):
		CombatLog.log_ability(tower, null, "Excavation")

		tower.user_real = tower.user_real + gold_bonus
		tower.get_player().give_gold(gold_bonus, tower, false, true)
	else:
		CombatLog.log_ability(tower, null, "Excavation Fail")
