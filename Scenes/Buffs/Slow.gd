class_name Slow
extends Buff


func _init():
	var slow_modifier: Modifier = Modifier.new()
	slow_modifier.add_modification(Modification.Type.MOD_MOVE_SPEED_ABSOLUTE, -100.0, 0.01)
	.set_modifier(slow_modifier)
