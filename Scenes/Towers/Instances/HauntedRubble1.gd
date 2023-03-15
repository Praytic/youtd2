extends Tower

# TODO: implement visual

func _get_tier_stats() -> Dictionary:
	return {
	1: {slow_value = 0.15, chance = 0.15, chance_add = 0.0015},
	2: {slow_value = 0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = 0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = 0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = 0.27, chance = 0.18, chance_add = 0.0018},
}


func _tower_init():
	var on_attack_buff = TriggersBuff.new()
	on_attack_buff.add_event_on_attack(self, "_on_attack", 1.0, 0.0)
	on_attack_buff.apply_to_unit_permanent(self, self, 0)


func _on_attack(event: Event):
	var tower: Unit = self
	var creep: Unit = event.get_target()
	var size: int = creep.get_size()
	var calc: bool

	if size == Unit.CreepSize.BOSS:
		calc = tower.calc_chance((_stats.chance + tower.get_level() * _stats.chance_add) * 2 / 3)
	else:
		calc = tower.calc_chance(_stats.chance + tower.get_level() * _stats.chance_add)

	if calc == true:
		var velex_slow: Buff = Buff.new("velex_slow", 0, 0, false)
		var slow: Modifier = Modifier.new()
		slow.add_modification(Unit.ModType.MOD_MOVESPEED, 0, -0.001)
		velex_slow.set_buff_icon("@@0@@")
		velex_slow.set_buff_modifier(slow)
		velex_slow.set_stacking_group("velex_slow1")

		velex_slow.apply_custom_timed(tower, event.get_target(), int(_stats.slow_value * 1000), 5.0)
