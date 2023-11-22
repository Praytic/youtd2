extends Tower


var Chainlightning_st: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {chain_damage = 150, on_attack_damage = 70},
		2: {chain_damage = 560, on_attack_damage = 260},
		3: {chain_damage = 1680, on_attack_damage = 770},
		4: {chain_damage = 4000, on_attack_damage = 1840},
	}


func get_ability_description() -> String:
	var chain_damage: String = Utils.format_float(_stats.chain_damage, 2)
	var chain_dmg_add: String = Utils.format_float(_stats.chain_damage * 0.02, 2)
	var on_attack_damage: String = Utils.format_float(_stats.on_attack_damage, 2)
	var on_attack_damage_add: String = Utils.format_float(_stats.on_attack_damage * 0.02, 2)

	var text: String = ""

	text += "[color=GOLD]Chainlightning[/color]\n"
	text += "This tower has a 19.5%% chance on attack to release a chainlightning that does %s damage and hits up to 3 units.\n" % chain_damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % chain_dmg_add
	text += "+0.25% chance\n"
	text += " \n"
	text += "[color=GOLD]Force Attack[/color]\n"
	text += "This tower deals %s spell damage on attack.\n" % on_attack_damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage" % on_attack_damage_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Chainlightning[/color]\n"
	text += "This tower has a chance on attack to release chainlightning.\n"
	text += " \n"
	text += "[color=GOLD]Force Attack[/color]\n"
	text += "This tower's attacks deal spell damage instead of attack damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	Chainlightning_st = SpellType.new("@@0@@", "chainlightning", 5.00, self)
	Chainlightning_st.data.chain_lightning.damage = _stats.chain_damage
	Chainlightning_st.data.chain_lightning.chain_count = 3


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.195 + tower.get_level() * 0.0025):
		return

	Chainlightning_st.target_cast_from_caster(tower, event.get_target(), 1.0 + tower.get_level() * 0.02, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.on_attack_damage * (1 + tower.get_level() * 0.02), tower.calc_spell_crit_no_bonus())
