extends Tower


var Chainlightning: Cast


func _get_tier_stats() -> Dictionary:
	return {
		1: {cast_data = 150, on_attack_damage = 70},
		2: {cast_data = 560, on_attack_damage = 260},
		3: {cast_data = 1680, on_attack_damage = 770},
		4: {cast_data = 4000, on_attack_damage = 1840},
	}



func load_triggers(triggers: BuffType):
	# triggers.add_event_on_damage(self, "on_attack", 0.195, 0.0025)
	triggers.add_event_on_damage(self, "on_attack", 0.995, 0.0025)
	triggers.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func tower_init():
	Chainlightning = Cast.new("@@0@@", "chainlightning", 5.00)
	Chainlightning.data.chain_lightning.damage = _stats.cast_data
	Chainlightning.data.chain_lightning.chain_count = 3


func on_attack(event: Event):
	print("on_attack")
	var tower: Tower = self

	Chainlightning.target_cast_from_caster(tower, event.get_target(), 1.0 + tower.get_level() * 0.02, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.on_attack_damage * (1 + tower.get_level() * 0.02), tower.calc_spell_crit_no_bonus())
