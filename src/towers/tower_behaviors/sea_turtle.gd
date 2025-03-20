extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_per_attack = 64, mana_per_attack_add = 2.56},
		2: {mana_per_attack = 128, mana_per_attack_add = 5.12},
		3: {mana_per_attack = 192, mana_per_attack_add = 7.68},
	}

const MANA_LOSS_PER_SEC: float = 0.0175


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1)


func on_attack(_event: Event):
	var mana_gain: float = max(_stats.mana_per_attack, (_stats.mana_per_attack + _stats.mana_per_attack_add * tower.get_level()) * tower.get_base_mana_regen_bonus_percent())

	tower.add_mana(mana_gain)


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var damage: float = tower.get_mana()
	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())


func periodic(_event: Event):
	var mana_loss: float = tower.get_mana() * MANA_LOSS_PER_SEC
	tower.subtract_mana(mana_loss, false)
