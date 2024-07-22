extends TowerBehavior


var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_bounty = 0.30, mod_bounty_add = 0.012, transmute_chance = 0.035, transmute_gold = 6, gold_greed_value = 16},
		2: {mod_bounty = 0.40, mod_bounty_add = 0.016, transmute_chance = 0.050, transmute_gold = 18, gold_greed_value = 44},
	}

const TRANSMUTE_CHANCE_ADD: float = 0.0004


func get_ability_info_list() -> Array[AbilityInfo]:
	var transmute_chance: String = Utils.format_percent(_stats.transmute_chance, 2)
	var transmute_chance_add: String = Utils.format_percent(TRANSMUTE_CHANCE_ADD, 2)
	var transmute_gold: String = Utils.format_float(_stats.transmute_gold, 2)
	var gold_greed_value: String = Utils.format_float(_stats.gold_greed_value, 2)

	var list: Array[AbilityInfo] = []
	
	var transmute: AbilityInfo = AbilityInfo.new()
	transmute.name = "Transmute"
	transmute.icon = "res://resources/icons/mechanical/gold_machine.tres"
	transmute.description_short = "Chance to turn hit creeps into gold. Doesn't work on bosses and champions.\n"
	transmute.description_full = "%s chance to turn hit creeps into %s additional gold immediately. Doesn't work on bosses and champions.\n" % [transmute_chance, transmute_gold] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % transmute_chance_add
	list.append(transmute)

	var gold_gree: AbilityInfo = AbilityInfo.new()
	gold_gree.name = "Gold Gree"
	gold_gree.icon = "res://resources/icons/misc/gold_cart.tres"
	gold_gree.description_short = "Deals additional spell damage to hit creeps. Damage scales with current player gold.\n"
	gold_gree.description_full = "Deals [color=GOLD][%s x squareroot (current gold)][/color] additional spell damage to hit creeps.\n" % gold_greed_value
	list.append(gold_gree)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, _stats.mod_bounty, _stats.mod_bounty_add)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Greed")


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var transmute_chance: float = _stats.transmute_chance + TRANSMUTE_CHANCE_ADD * tower.get_level()
	var gold_greed_damage: float = get_current_gold_greed_damage()

	if creep.is_immune():
		return

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance(transmute_chance):
		CombatLog.log_ability(tower, creep, "Transmute")

		SFX.sfx_at_unit(SfxPaths.PICKUP_GOLD, creep)
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
