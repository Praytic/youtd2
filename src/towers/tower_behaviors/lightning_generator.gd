extends TowerBehavior


var chainlight_st: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {chain_damage = 150, on_attack_damage = 70},
		2: {chain_damage = 560, on_attack_damage = 260},
		3: {chain_damage = 1680, on_attack_damage = 770},
		4: {chain_damage = 4000, on_attack_damage = 1840},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var chain_damage: String = Utils.format_float(_stats.chain_damage, 2)
	var chain_dmg_add: String = Utils.format_float(_stats.chain_damage * 0.02, 2)
	var on_attack_damage: String = Utils.format_float(_stats.on_attack_damage, 2)
	var on_attack_damage_add: String = Utils.format_float(_stats.on_attack_damage * 0.02, 2)

	var list: Array[AbilityInfo] = []
	
	var chain: AbilityInfo = AbilityInfo.new()
	chain.name = "Chain Lightning"
	chain.icon = "res://resources/icons/electricity/thunderstorm.tres"
	chain.description_short = "On attack, this tower has a chance to release [color=GOLD]Chain Lightning[/color], dealing spell damage.\n"
	chain.description_full = "On attack, this tower has a 19.5%% chance to release a [color=GOLD]Chain Lightning[/color] that does %s spell damage and hits up to 3 units.\n" % chain_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % chain_dmg_add \
	+ "+0.25% chance\n"
	list.append(chain)

	var force_attack: AbilityInfo = AbilityInfo.new()
	force_attack.name = "Force Attack"
	force_attack.icon = "res://resources/icons/tower_icons/charged_obelisk.tres"
	force_attack.description_short = "This tower's attacks deal spell damage instead of attack damage.\n"
	force_attack.description_full = "This tower's attacks deal %s spell damage instead of attack damage.\n" % on_attack_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage" % on_attack_damage_add
	list.append(force_attack)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	chainlight_st = SpellType.new(SpellType.Name.CHAIN_LIGHTNING, 5.00, self)
	chainlight_st.data.chain_lightning.damage = _stats.chain_damage
	chainlight_st.data.chain_lightning.chain_count = 3


func on_attack(event: Event):
	if !tower.calc_chance(0.195 + tower.get_level() * 0.0025):
		return

	CombatLog.log_ability(tower, event.get_target(), "Chainlightning")

	chainlight_st.target_cast_from_caster(tower, event.get_target(), 1.0 + tower.get_level() * 0.02, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.on_attack_damage * (1 + tower.get_level() * 0.02), tower.calc_spell_crit_no_bonus())
