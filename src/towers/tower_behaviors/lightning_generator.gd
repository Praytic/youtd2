extends TowerBehavior


var chainlight_st: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {chain_damage = 150, on_attack_damage = 70},
		2: {chain_damage = 560, on_attack_damage = 260},
		3: {chain_damage = 1680, on_attack_damage = 770},
		4: {chain_damage = 4000, on_attack_damage = 1840},
	}


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
