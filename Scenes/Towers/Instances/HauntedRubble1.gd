extends Tower

# TODO: implement visual

const _stats_map: Dictionary = {
	1: {slow_value = 0.15, chance = 0.15, chance_add = 0.0015},
	2: {slow_value = 0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = 0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = 0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = 0.27, chance = 0.18, chance_add = 0.0018},
}


func _ready():
	var on_attack_buff: Buff = Buff.new("")
	on_attack_buff.add_event_handler(Buff.EventType.ATTACK, self, "_on_attack")
	on_attack_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_attack(event: Event):
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var tower: Unit = self
	var creep: Unit = event.get_target()
	var size: int = creep.get_size()
	var calc: bool

	if size == Mob.Size.BOSS:
		calc = tower.calc_chance((stats.chance + tower.get_level() * stats.chance_add) * 2 / 3)
	else:
		calc = tower.calc_chance(stats.chance + tower.get_level() * stats.chance_add)

	if calc == true:
		var velex_slow: Buff = Buff.new("velex_slow")
		var slow: Modifier = Modifier.new()
		slow.add_modification(Modification.Type.MOD_MOVE_SPEED, 0, -0.001)
		velex_slow.set_buff_icon("@@0@@")
		velex_slow.set_buff_modifier(slow)
		velex_slow.set_stacking_group("velex_slow1")

		velex_slow.apply_to_unit(tower, event.get_target(), int(stats.slow_value * 1000), 5.0, 0.0, false)
