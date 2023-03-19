extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {self_attackspeed_add = 0.0, buff_scale = 6},
		2: {self_attackspeed_add = 1.5, buff_scale = 9},
		3: {self_attackspeed_add = 1.8, buff_scale = 12},
		4: {self_attackspeed_add = 2.1, buff_scale = 15},
		5: {self_attackspeed_add = 2.4, buff_scale = 18},
	}


func _tower_init():
	var on_damage_buff: Buff = TriggersBuff.new()
	on_damage_buff.add_event_on_damage(self, "on_damage", 0.3, 0.0)
	on_damage_buff.apply_to_unit_permanent(self, self, 0)

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, _stats.self_attackspeed_add)
	add_modifier(specials_modifier)


func make_cedi_stormdog_buff() -> Buff:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0005)

	var cedi_stormdog: Buff = Buff.new("cedi_stormdog", 5.0, 0.0, true)
	cedi_stormdog.set_buff_icon("@@1@@")
	cedi_stormdog.set_buff_modifier(mod)

	return cedi_stormdog


func on_damage(event: Event):
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

		B = U.get_buff_of_type("cedi_stormdog")

		if B != null:
			if B.user_int < 100:
				var cedi_stormdog: Buff = make_cedi_stormdog_buff()
				cedi_stormdog.apply(tower, U, B.get_level() + 6)
				B.user_int = B.user_int + 1
			else:
				B.refresh_duration()
		else:
			var cedi_stormdog: Buff = make_cedi_stormdog_buff()
			cedi_stormdog.apply(tower, U, tower.get_level() * 6)
			B = cedi_stormdog
			B.user_int = 0
