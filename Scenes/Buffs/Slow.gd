extends Buff


class_name Slow


func _init(tower_arg: Tower, time: float, time_level_add: float, value_modifier: float, power_level: int).(tower_arg, time, time_level_add, value_modifier, power_level):
	var slow_modifier: Modifier = Modifier.new()
	slow_modifier.add_modification(Modification.Type.MOD_MOVE_SPEED, -100.0, 0.01)
	.set_modifier(slow_modifier)
