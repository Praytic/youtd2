extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_base = 0.3},
		2: {miss_chance_base = 0.4},
		3: {miss_chance_base = 0.5},
		4: {miss_chance_base = 0.6},
		5: {miss_chance_base = 0.7},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func on_damage(event: Event):
	var tower = self

	if tower.calc_bad_chance(_stats.miss_chance_base - tower.get_level() * 0.006):
		event.damage = 0
		Utils.display_floating_text_x("Miss", tower, 255, 0, 0, 255, 0.05, 0.0, 2.0)
