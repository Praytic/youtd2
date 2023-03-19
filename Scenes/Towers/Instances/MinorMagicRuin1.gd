extends Tower


# TODO: implement visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {exp_bonus = 0.05, exp_bonus_add = 0.002},
		2: {exp_bonus = 0.10, exp_bonus_add = 0.004},
		3: {exp_bonus = 0.15, exp_bonus_add = 0.006},
		4: {exp_bonus = 0.20, exp_bonus_add = 0.008},
		5: {exp_bonus = 0.25, exp_bonus_add = 0.010},
		6: {exp_bonus = 0.30, exp_bonus_add = 0.012},
	}


func _tower_init():
	var on_damage_buff: Buff = TriggersBuff.new()
	on_damage_buff.add_event_on_damage(self, "_on_damage", 1.0, 0.0)
	on_damage_buff.apply_to_unit_permanent(self, self, 0)


func _on_damage(event: Event):
	var tower = self

	var astral_mod: Modifier = Modifier.new()
	var drol_magic_ruin = Buff.new("drol_magic_ruin", 5, 0, false)
	astral_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, _stats.exp_bonus, _stats.exp_bonus_add)
	drol_magic_ruin.set_buff_modifier(astral_mod)
	drol_magic_ruin.set_buff_icon("@@0@@")

	drol_magic_ruin.apply_custom_timed(tower, event.get_target(), tower.get_level(), 5 + tower.get_level() * 0.2)
