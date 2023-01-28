extends Tower


func on_attack(event: Event):
	var slow: Buff = Slow.new(self, 5.0, 1.0, 0)
	var target: Mob = event.target
	target.apply_buff(slow)
