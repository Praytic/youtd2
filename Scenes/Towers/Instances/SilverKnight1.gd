extends Tower


var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_bounty = 0.30, mod_bounty_add = 0.012, transmute_chance = 0.035, transmute_gold = 6, gold_greed_value = 16},
		2: {mod_bounty = 0.40, mod_bounty_add = 0.016, transmute_chance = 0.050, transmute_gold = 18, gold_greed_value = 44},
	}

const TRANSMUTE_CHANCE_ADD: float = 0.0004


func get_ability_description() -> String:
	var transmute_chance: String = Utils.format_percent(_stats.transmute_chance, 2)
	var transmute_chance_add: String = Utils.format_percent(TRANSMUTE_CHANCE_ADD, 2)
	var transmute_gold: String = Utils.format_float(_stats.transmute_gold, 2)
	var gold_greed_value: String = Utils.format_float(_stats.gold_greed_value, 2)

	var text: String = ""

	text += "[color=GOLD]Transmute[/color]\n"
	text += "This tower has a %s chance on attack to turn a non boss, non champion target into %s additional gold immediately.\n" % [transmute_chance, transmute_gold]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % transmute_chance_add
	text += " \n"
	text += "[color=GOLD]Gold Gree[/color]\n"
	text += "On attack this tower deals [%s x squareroot (current gold)] spell damage to its target.\n" % gold_greed_value

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Transmute[/color]\n"
	text += "This tower has a chance on attack to turn a lesser creep into gold.\n"
	text += " \n"
	text += "[color=GOLD]Gold Gree[/color]\n"
	text += "On attack this tower deals spell damage which scales with current player gold.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, _stats.mod_bounty, _stats.mod_bounty_add)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Greed")


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var transmute_chance: float = _stats.transmute_chance + TRANSMUTE_CHANCE_ADD * tower.get_level()
	var gold_greed_damage: float = get_current_gold_greed_damage()

	if creep.is_immune():
		return

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance(transmute_chance):
		SFX.sfx_at_unit("PileofGold.mdl", creep)
		tower.kill_instantly(creep)
		tower.get_player().give_gold(_stats.transmute_gold, tower, true, true)
	else:
		tower.do_spell_damage(creep, gold_greed_damage, tower.calc_spell_crit_no_bonus())
		var gold_greed_text: String = str(int(tower.get_prop_spell_damage_dealt() * gold_greed_damage))
		tower.get_player().display_floating_text_x(gold_greed_text, creep, 255, 200, 0, 255, 0.05, 0.0, 2.0)



func on_tower_details() -> MultiboardValues:
	var gold_greed_damage: float = get_current_gold_greed_damage()	
	var gold_greed_damage_string: String = Utils.format_float(roundf(gold_greed_damage), 2)
	multiboard.set_value(0, gold_greed_damage_string)

	return multiboard


func get_current_gold_greed_damage() -> float:
	var current_gold: float = GoldControl.get_gold()
	var damage: float = _stats.gold_greed_value * pow(current_gold, 0.5)

	return damage
