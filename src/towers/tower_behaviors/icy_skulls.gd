extends TowerBehavior


var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {slow_base = 0.075, slow_add = 0.003, duration_base = 3, duration_add = 0.1},
		2: {slow_base = 0.100, slow_add = 0.004, duration_base = 4, duration_add = 0.2},
		3: {slow_base = 0.125, slow_add = 0.005, duration_base = 5, duration_add = 0.3},
		4: {slow_base = 0.150, slow_add = 0.006, duration_base = 6, duration_add = 0.4},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", _stats.duration_base, _stats.duration_add, false, self)
	var slow_mod: Modifier = Modifier.new()
	slow_mod.add_modification(ModificationType.enm.MOD_MOVESPEED, -_stats.slow_base, -_stats.slow_add)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow_mod)

	slow_bt.set_buff_tooltip(tr("PTSP"))


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()

	slow_bt.apply(tower, target, lvl)
