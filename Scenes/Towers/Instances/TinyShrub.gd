extends Tower


func on_attack(event: Event):
	var test_buff: BuffType = BuffTypeStorage.test_buff
	var target: Mob = event.target
	test_buff.apply(self, target, 1.0)
