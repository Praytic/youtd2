extends Tower

# TODO: implement visual


const _stats_map: Dictionary = {
	1: {slow_base = 0.075, slow_add = 0.003, duration_base = 3, duration_add = 0.1},
	2: {slow_base = 0.100, slow_add = 0.004, duration_base = 4, duration_add = 0.2},
	3: {slow_base = 0.125, slow_add = 0.005, duration_base = 5, duration_add = 0.3},
	4: {slow_base = 0.150, slow_add = 0.006, duration_base = 6, duration_add = 0.4},
}


func _ready():
	var on_damage_buff: Buff = Buff.new("on_damage_buff")
	on_damage_buff.add_event_handler(Buff.EventType.DAMAGE, self, "_on_damage")
	on_damage_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var tower = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var cassim_slow = Buff.new("cassim_slow")
	var slow_mod: Modifier = Modifier.new()
	slow_mod.add_modification(Modification.Type.MOD_MOVE_SPEED, 0, -0.001)
	cassim_slow.set_buff_icon("@@0@@")
	cassim_slow.set_buff_modifier(slow_mod)

	var lvl: int = tower.get_level()
	var slow: int = int((stats.slow_base + lvl * stats.slow_add) * 1000)
	var dur: int = int(stats.duration_base + lvl * stats.duration_add)

	cassim_slow.apply_to_unit(tower, event.get_target(), slow, dur, 0.0, false)
