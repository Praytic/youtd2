extends Tower

# TODO: implement visual

const _stats_map: Dictionary = {
	1: {slow_value = -0.15, chance = 0.15, chance_add = 0.0015},
	2: {slow_value = -0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = -0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = -0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = -0.27, chance = 0.18, chance_add = 0.0018},
}


func _ready():
	var atrophy_trigger: Buff = Buff.new("atrophy_trigger")
	atrophy_trigger.add_event_handler(Buff.EventType.ATTACK, self, "_on_attack")
	atrophy_trigger.apply_to_unit_permanent(self, self, 0, false)


func _on_attack(event: Event):
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var tower: Unit = self
	var mob: Unit = event.get_target()
	var size: int = mob.get_size()

	var apply_chance: float = (stats.chance + tower.get_level() * stats.chance_add)

	if size == Mob.Size.BOSS:
		apply_chance *= 2 / 3

	var chance_success: bool = tower.calc_chance(apply_chance)

	if chance_success:
		var atrophy: Buff = Buff.new("velex_slow")
		var slow: Modifier = Modifier.new()
		slow.add_modification(Modification.Type.MOD_MOVE_SPEED, stats.slow_value, 0.0)
		atrophy.set_buff_icon("@@0@@")
		atrophy.set_buff_modifier(slow)
		atrophy.set_stacking_group("velex_slow1")

		var power_level: int = tier
		atrophy.apply_to_unit(tower, mob, power_level, 5.0, 0.0, false)
