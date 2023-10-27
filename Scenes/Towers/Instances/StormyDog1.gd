extends Tower


var cedi_stormdog: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {self_attackspeed_add = 0.0, buff_scale = 6},
		2: {self_attackspeed_add = 0.015, buff_scale = 9},
		3: {self_attackspeed_add = 0.018, buff_scale = 12},
		4: {self_attackspeed_add = 0.021, buff_scale = 15},
		5: {self_attackspeed_add = 0.024, buff_scale = 18},
	}


func get_ability_description() -> String:
	var attack_speed: String = Utils.format_percent(_stats.buff_scale * 0.0005, 2)

	var text: String = ""

	text += "[color=GOLD]Thunderous Roar[/color]\n"
	text += "Whenever this tower damages a unit it has 30%% chance to release a battle cry. The cry increases the attack speed of all towers in 420 range by 5%% for 5 seconds. If a tower already has the thunderous roar buff the attack speed is increased by %s and the duration is refreshed. Stacks up to 100 times.\n" % attack_speed
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s attack speed" % attack_speed

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, _stats.self_attackspeed_add)


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0005)

	cedi_stormdog = BuffType.new("cedi_stormdog", 5.0, 0.0, true, self)
	cedi_stormdog.set_buff_icon("@@1@@")
	cedi_stormdog.set_buff_modifier(mod)
	cedi_stormdog.set_buff_tooltip("Thunderous Roar\nThis unit is affected by Thunderous Roar; it has increased attack speed.")


func on_damage(_event: Event):
	var tower: Unit = self

	if !tower.calc_chance(0.3):
		return

	var I: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)
	var U: Unit
	var B: Buff

	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", tower, "origin")
	Effect.destroy_effect_after_its_over(effect)

	while true:
		U = I.next()

		if U == null:
			break

		B = U.get_buff_of_type(cedi_stormdog)

		if B != null:
			if B.user_int < 100:
				cedi_stormdog.apply(tower, U, B.get_level() + _stats.buff_scale)
				B.user_int = B.user_int + 1
			else:
				B.refresh_duration()
		else:
			B = cedi_stormdog.apply(tower, U, tower.get_level() * _stats.buff_scale)
			B.user_int = 0
