extends Tower

# TODO: implement visual

func _get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_add = 0.008},
		2: {miss_chance_add = 0.009},
		3: {miss_chance_add = 0.010},
		4: {miss_chance_add = 0.011},
		5: {miss_chance_add = 0.012},
		6: {miss_chance_add = 0.013},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func load_specials():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, -0.03)
	add_modifier(modifier)


func on_damage(event: Event):
	var tower = self

	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		event.damage = 0
		Utils.display_floating_text_x("Miss", tower, 255, 0, 0, 0.05, 0.0, 2.0)
