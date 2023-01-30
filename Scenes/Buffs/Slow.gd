class_name Slow
extends Buff


func _init(tower_arg: Tower, time: float, time_level_add: float, power_level: int, friendly: bool).(tower_arg, time, time_level_add, power_level, friendly):
	var slow_modifier: Modifier = Modifier.new()
	slow_modifier.add_modification(Modification.Type.MOD_MOVE_SPEED_ABSOLUTE, -100.0, 0.01)
	.set_modifier(slow_modifier)
