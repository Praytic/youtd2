extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana_add = 64, mana_per_attack = 64, mana_per_attack_add = 2.56},
		2: {mod_mana_add = 128, mana_per_attack = 128, mana_per_attack_add = 5.12},
		3: {mod_mana_add = 192, mana_per_attack = 192, mana_per_attack_add = 7.68},
	}

const MANA_LOSS_PER_SEC: float = 0.0175


func get_extra_tooltip_text() -> String:
	var mana_per_attack: String = Utils.format_float(_stats.mana_per_attack, 2)
	var mana_per_attack_add: String = Utils.format_float(_stats.mana_per_attack_add, 2)
	var mana_loss_per_sec: String = Utils.format_percent(MANA_LOSS_PER_SEC, 2)

	var text: String = ""

	text += "[color=GOLD]Splash[/color]\n"
	text += "Every attack the turtle restores %s mana. Mana regeneration will increase mana restored. Mana degeneration will not decrease mana restored below %s.\n" % [mana_per_attack, mana_per_attack]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s mana restored\n" % mana_per_attack_add
	text += " \n"
	text += "[color=GOLD]Aqua Breath[/color]\n"
	text += "This tower deals Energy damage equal to its mana.\n"
	text += " \n"
	text += "[color=GOLD]Cold Blooded[/color]\n"
	text += "Every second this tower loses %s of its max mana.\n" % mana_loss_per_sec

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, _stats.mod_mana_add)


func on_attack(_event: Event):
	var tower: Tower = self
	var mana_gain: float = max(_stats.mana_per_attack, (_stats.mana_per_attack + _stats.mana_per_attack_add * tower.get_level()) * tower.get_base_mana_regen_bonus_percent())

	tower.add_mana(mana_gain)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var damage: float = tower.get_mana()
	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())


func periodic(_event: Event):
	var tower: Tower = self
	var mana_loss: float = tower.get_mana() * MANA_LOSS_PER_SEC
	tower.subtract_mana(mana_loss, false)
