extends Tower

const _stats_map: Dictionary = {
	1: {damage_base = 0.15, damage_add = 0.006},
	2: {damage_base = 0.20, damage_add = 0.008},
	3: {damage_base = 0.25, damage_add = 0.010},
	4: {damage_base = 0.30, damage_add = 0.012},
}


func _ready():
	var on_damage_buff: Buff = Buff.new("on_damage_buff")
	on_damage_buff.add_event_handler(Buff.EventType.DAMAGE, self, "_on_damage")
	on_damage_buff.apply_to_unit_permanent(self, self, 0, false)


func _on_damage(event: Event):
	var tower: Unit = self
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	if event.get_target().is_invisible():
		event.damage = event.damage * (stats.damage_base * stats.damage_add * tower.get_level())
