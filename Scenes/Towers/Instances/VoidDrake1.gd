extends Tower


var cb_silence: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_exp_gain = 0.50, mod_exp_gain_add = 0.06, mod_damage_add = 0.12, silence_duration = 1.25, silence_duration_add = 0.07, boss_silence_multiplier = 0.33, void_exp_loss = 0.010, void_exp_loss_add = 0.0002},
		2: {mod_exp_gain = 0.80, mod_exp_gain_add = 0.10, mod_damage_add = 0.20, silence_duration = 1.25, silence_duration_add = 0.13, boss_silence_multiplier = 0.25, void_exp_loss = 0.015, void_exp_loss_add = 0.0003},
	}


func get_ability_description() -> String:
	var is_first_tier: bool = get_tier() == 1

	var silence_duration: String = Utils.format_float(_stats.silence_duration, 2)
	var silence_duration_add: String = Utils.format_float(_stats.silence_duration_add, 2)
	var boss_silence_multiplier: String = Utils.format_percent(_stats.boss_silence_multiplier, 2)
	var void_exp_loss: String = Utils.format_percent(_stats.void_exp_loss, 2)
	var void_exp_loss_add: String = Utils.format_percent(_stats.void_exp_loss_add, 2)

	var text: String = ""

	text += "[color=GOLD]Silence[/color]\n"
	text += "Units damaged by this tower are silenced for %s seconds. Bosses are silenced only for %s of the normal duration.\n" % [silence_duration, boss_silence_multiplier]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds duration\n" % silence_duration_add
	text += " \n"
	text += "[color=GOLD]Void[/color]\n"
	text += "Every second, this unit loses %s of its experience. This tower will not lose levels in this way. Replacing a tower with this tower will reset the experience to 0 unless the replaced tower is of this tower's family.\n" % void_exp_loss
	if is_first_tier:
		text += "When this tower is upgraded or replaced to Void Dragon, it loses experience equal to 50% of its current experience.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s periodical experience lost\n" % void_exp_loss_add
	if is_first_tier:
		text += "+1% upgrade experience lost\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -_stats.mod_exp_gain, -_stats.mod_exp_gain_add)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.04)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, _stats.mod_damage_add)


func tower_init():
	cb_silence = CbSilence.new("void_drake_silence", 0, 0, false, self)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()

	var silence_duration: float = _stats.silence_duration + _stats.silence_duration_add * tower.get_level()
	if creep.get_size() == CreepSize.enm.BOSS:
		silence_duration = silence_duration * _stats.boss_silence_multiplier

	cb_silence.apply_only_timed(tower, event.get_target(), silence_duration)


func periodic(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var current_exp: float = tower.get_exp()
	var exp_for_level: int = Experience.get_exp_for_level(level)
	var exp_before_level_down: float = current_exp - exp_for_level
	var exp_removed: float = current_exp * (_stats.void_exp_loss + _stats.void_exp_loss_add * level)

	if exp_removed > exp_before_level_down:
		exp_removed = exp_before_level_down

	if exp_removed >= 0.1 && level != 25:
		tower.remove_exp_flat(exp_removed)


func on_create(preceding: Tower):
	var tower: Tower = self
	
	if preceding == null:
		return
	
	var same_family: bool = tower.get_family() == preceding.get_family()

	if same_family:
		var exp_loss: float = tower.get_exp() * (0.5 + 0.01 * tower.get_level())
		tower.remove_exp_flat(exp_loss)
	else:
		var exp_loss: float = tower.get_exp()
		tower.remove_exp_flat(exp_loss)
