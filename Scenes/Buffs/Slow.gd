extends Buff


class_name Slow


func _init(tower_arg: Tower, time: float, value_modifier: float, power_level: int).(tower_arg, time, value_modifier, power_level):
	var slow_modifier: Modifier = Modifier.new()
	slow_modifier.add_modification(Modification.Type.MOD_MOVE_SPEED, 0, -100.0)
	.set_modifier(slow_modifier)
