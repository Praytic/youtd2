extends Node


var test_buff: BuffType = make_test_buff()
func make_test_buff() -> BuffType:
	var out: BuffType = BuffType.new(5.0)
	add_child(out)

	var slow: Modifier = Modifier.new()
	slow.add_modification(Modifier.ModificationType.MOD_MOVE_SPEED, 0, -100.0)
	out.set_modifier(slow)
	
	return out


# NOTE: other buff types created the same way as test_buff
