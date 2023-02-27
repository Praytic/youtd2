extends Tower

# TODO: implement visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {slow_base = 0.075, slow_add = 0.003, duration_base = 3, duration_add = 0.1},
		2: {slow_base = 0.100, slow_add = 0.004, duration_base = 4, duration_add = 0.2},
		3: {slow_base = 0.125, slow_add = 0.005, duration_base = 5, duration_add = 0.3},
		4: {slow_base = 0.150, slow_add = 0.006, duration_base = 6, duration_add = 0.4},
	}


func _ready():
	var on_damage_buff: Buff = TriggersBuff.new()
	on_damage_buff.add_event_on_damage(self, "_on_damage", 1.0, 0.0)
	on_damage_buff.apply_to_unit_permanent(self, self, 0)


func _on_damage(event: Event):
	var tower = self

	var cassim_slow = Buff.new("cassim_slow", 0, 0, false)
	var slow_mod: Modifier = Modifier.new()
	slow_mod.add_modification(Unit.ModType.MOD_MOVE_SPEED, 0, -0.001)
	cassim_slow.set_buff_icon("@@0@@")
	cassim_slow.set_buff_modifier(slow_mod)

	var lvl: int = tower.get_level()
	var slow: int = int((_stats.slow_base + lvl * _stats.slow_add) * 1000)
	var dur: int = int(_stats.duration_base + lvl * _stats.duration_add)

	cassim_slow.apply_custom_timed(tower, event.get_target(), slow, dur)
