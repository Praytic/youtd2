extends TowerBehavior


var silence_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_damage_add = 0.12, silence_duration = 1.25, silence_duration_add = 0.07, boss_silence_multiplier = 0.33, void_exp_loss = 0.010, void_exp_loss_add = 0.0002},
		2: {mod_damage_add = 0.20, silence_duration = 1.75, silence_duration_add = 0.13, boss_silence_multiplier = 0.25, void_exp_loss = 0.015, void_exp_loss_add = 0.0003},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func tower_init():
	silence_bt = CbSilence.new("void_drake_silence", 0, 0, false, self)


func on_damage(event: Event):
	var creep: Unit = event.get_target()

	var silence_duration: float = _stats.silence_duration + _stats.silence_duration_add * tower.get_level()
	if creep.get_size() == CreepSize.enm.BOSS:
		silence_duration = silence_duration * _stats.boss_silence_multiplier

	silence_bt.apply_only_timed(tower, event.get_target(), silence_duration)


func periodic(_event: Event):
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
	if preceding == null:
		return
	
	var same_family: bool = tower.get_family() == preceding.get_family()

	if same_family:
		var exp_loss: float = tower.get_exp() * (0.5 + 0.01 * tower.get_level())
		tower.remove_exp_flat(exp_loss)
	else:
		var exp_loss: float = tower.get_exp()
		tower.remove_exp_flat(exp_loss)
