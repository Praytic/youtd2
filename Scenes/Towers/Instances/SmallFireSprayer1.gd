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


func _ready():
	var on_damage_buff = TriggersBuff.new()
	on_damage_buff.add_event_on_damage(self, "on_damage", 1.0, 0.0)
	on_damage_buff.apply_to_unit_permanent(self, self, 0)

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Unit.ModType.MOD_ATTACKSPEED, 0, -0.03)
	add_modifier(specials_modifier)


func on_damage(event: Event):
	var tower = self

	if tower.calc_bad_chance(0.33 - _stats.miss_chance_add * tower.get_level()):
		event.damage = 0
		Utils.display_floating_text_x("Miss", tower, 255, 0, 0, 0.05, 0.0, 2.0)
