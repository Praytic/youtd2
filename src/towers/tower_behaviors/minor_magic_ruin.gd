extends TowerBehavior


var illuminate_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {exp_bonus = 0.05, exp_bonus_add = 0.002},
		2: {exp_bonus = 0.10, exp_bonus_add = 0.004},
		3: {exp_bonus = 0.15, exp_bonus_add = 0.006},
		4: {exp_bonus = 0.20, exp_bonus_add = 0.008},
		5: {exp_bonus = 0.25, exp_bonus_add = 0.010},
		6: {exp_bonus = 0.30, exp_bonus_add = 0.012},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	var astral_mod: Modifier = Modifier.new()
	illuminate_bt = BuffType.new("illuminate_bt", 5, 0, false, self)
	astral_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, _stats.exp_bonus, _stats.exp_bonus_add)
	illuminate_bt.set_buff_modifier(astral_mod)
	illuminate_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	
	illuminate_bt.set_buff_tooltip(tr("ODJT"))


func on_damage(event: Event):
	illuminate_bt.apply_custom_timed(tower, event.get_target(), tower.get_level(), 5 + tower.get_level() * 0.2)
