extends TowerBehavior


var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {transmute_chance = 0.035, transmute_gold = 6, gold_greed_value = 16},
		2: {transmute_chance = 0.050, transmute_gold = 18, gold_greed_value = 44},
	}

const TRANSMUTE_CHANCE_ADD: float = 0.0004


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	multiboard = MultiboardValues.new(1)
	var gold_greed_damage_label: String = tr("DUIY")
	multiboard.set_key(0, gold_greed_damage_label)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var transmute_chance: float = _stats.transmute_chance + TRANSMUTE_CHANCE_ADD * tower.get_level()
	var gold_greed_damage: float = get_current_gold_greed_damage()

	if creep.is_immune():
		return

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance(transmute_chance):
		CombatLog.log_ability(tower, creep, "Transmute")

		tower.kill_instantly(creep)
		tower.get_player().give_gold(_stats.transmute_gold, tower, true, true)
	else:
		tower.do_spell_damage(creep, gold_greed_damage, tower.calc_spell_crit_no_bonus())
		var gold_greed_text: String = str(int(tower.get_prop_spell_damage_dealt() * gold_greed_damage))
		tower.get_player().display_floating_text_x(gold_greed_text, creep, Color8(255, 200, 0, 255), 0.05, 0.0, 2.0)



func on_tower_details() -> MultiboardValues:
	var gold_greed_damage: float = get_current_gold_greed_damage()	
	var gold_greed_damage_string: String = Utils.format_float(roundf(gold_greed_damage), 2)
	multiboard.set_value(0, gold_greed_damage_string)

	return multiboard


func get_current_gold_greed_damage() -> float:
	var current_gold: float = tower.get_player().get_gold()
	var damage: float = _stats.gold_greed_value * pow(current_gold, 0.5)

	return damage
