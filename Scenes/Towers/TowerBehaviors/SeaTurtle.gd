extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana_add = 64, mana_per_attack = 64, mana_per_attack_add = 2.56},
		2: {mod_mana_add = 128, mana_per_attack = 128, mana_per_attack_add = 5.12},
		3: {mod_mana_add = 192, mana_per_attack = 192, mana_per_attack_add = 7.68},
	}

const MANA_LOSS_PER_SEC: float = 0.0175


func get_ability_info_list() -> Array[AbilityInfo]:
	var mana_per_attack: String = Utils.format_float(_stats.mana_per_attack, 2)
	var mana_per_attack_add: String = Utils.format_float(_stats.mana_per_attack_add, 2)
	var mana_loss_per_sec: String = Utils.format_percent(MANA_LOSS_PER_SEC, 2)

	var list: Array[AbilityInfo] = []
	
	var splash: AbilityInfo = AbilityInfo.new()
	splash.name = "Splash"
	splash.description_short = "Every attack the turtle restores some mana.\n"
	splash.description_full = "Every attack the turtle restores %s mana. Mana regeneration will increase mana restored. Mana degeneration will not decrease mana restored below %s.\n" % [mana_per_attack, mana_per_attack] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s mana restored\n" % mana_per_attack_add
	list.append(splash)

	var aqua_breath: AbilityInfo = AbilityInfo.new()
	aqua_breath.name = "Aqua Breath"
	aqua_breath.description_short = "This tower deals Energy damage equal to its mana.\n"
	aqua_breath.description_full = "This tower deals Energy damage equal to its mana.\n"
	list.append(aqua_breath)

	var cold_blooded: AbilityInfo = AbilityInfo.new()
	cold_blooded.name = "Cold Blooded"
	cold_blooded.description_short = "Every second this tower loses some of its mana.\n"
	cold_blooded.description_full = "Every second this tower loses %s of its max mana.\n" % mana_loss_per_sec
	list.append(cold_blooded)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, _stats.mod_mana_add)


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
