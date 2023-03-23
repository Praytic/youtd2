extends Tower


var cedi_stormdog: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {self_attackspeed_add = 0.0, buff_scale = 6},
		2: {self_attackspeed_add = 1.5, buff_scale = 9},
		3: {self_attackspeed_add = 1.8, buff_scale = 12},
		4: {self_attackspeed_add = 2.1, buff_scale = 15},
		5: {self_attackspeed_add = 2.4, buff_scale = 18},
	}


func _load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", 0.3, 0.0)


func tower_init():
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, _stats.self_attackspeed_add)
	add_modifier(specials_modifier)


	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0005)

	cedi_stormdog = BuffType.new("cedi_stormdog", 5.0, 0.0, true)
	cedi_stormdog.set_buff_icon("@@1@@")
	cedi_stormdog.set_buff_modifier(mod)


func on_damage(_event: Event):
	var tower: Unit = self

	var I: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)
	var U: Unit
	var B: Buff

	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", tower, "origin")
	Effect.destroy_effect(effect)

	while true:
		U = I.next()

		if U == null:
			break

		B = U.get_buff_of_type(cedi_stormdog)

		if B != null:
			if B.user_int < 100:
				cedi_stormdog.apply(tower, U, B.get_level() + 6)
				B.user_int = B.user_int + 1
			else:
				B.refresh_duration()
		else:
			B = cedi_stormdog.apply(tower, U, tower.get_level() * 6)
			B.user_int = 0
