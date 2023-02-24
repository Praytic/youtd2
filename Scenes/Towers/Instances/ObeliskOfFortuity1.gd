extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_base = 30},
		2: {miss_chance_base = 40},
		3: {miss_chance_base = 50},
		4: {miss_chance_base = 60},
		5: {miss_chance_base = 70},
	}


func _ready():
	var warming_up = Buff.new("")
	warming_up.add_event_handler(Buff.EventType.DAMAGE, self, "on_damage")
	warming_up.apply_to_unit_permanent(self, self, 0, true)


func on_damage(event: Event):
	var tower = self

	if tower.calc_bad_chance(_stats.miss_chance_base - tower.get_level() * 0.006):
		event.damage = 0
		Utils.display_floating_text_x("Miss", tower, 255, 0, 0, 0.05, 0.0, 2.0)
