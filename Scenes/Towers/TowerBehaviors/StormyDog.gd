extends TowerBehavior


var roar_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {self_attack_speed_add = 0.0, buff_scale = 6},
		2: {self_attack_speed_add = 0.015, buff_scale = 9},
		3: {self_attack_speed_add = 0.018, buff_scale = 12},
		4: {self_attack_speed_add = 0.021, buff_scale = 15},
		5: {self_attack_speed_add = 0.024, buff_scale = 18},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var attack_speed: String = Utils.format_percent(_stats.buff_scale * 0.0005, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Thunderous Roar"
	ability.icon = "res://resources/Icons/animals/dragon_03.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance to release a [color=GOLD]Thunderous Roar[/color], increasing attack speed of nearby towers.\n"
	ability.description_full = "Whenever this tower hits a creep, it has a 30%% chance to release a [color=GOLD]Thunderous Roar[/color]. [color=GOLD]Thunderous Roar[/color] increases attack speed of all towers in 420 range by 5%% for 5 seconds. If a tower already has [color=GOLD]Thunderous Roar[/color], then attack speed is increased by %s and duration is refreshed. Stacks up to 100 times.\n" % attack_speed \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack speed" % attack_speed
	ability.radius = 420
	ability.target_type = TargetType.new(TargetType.TOWERS)
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game does NOT
# include innate stats
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, _stats.self_attack_speed_add)


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0005)

	roar_bt = BuffType.new("roar_bt", 5.0, 0.0, true, self)
	roar_bt.set_buff_icon("res://resources/Icons/GenericIcons/wolf_howl.tres")
	roar_bt.set_buff_modifier(mod)
	roar_bt.set_buff_tooltip("Thunderous Roar\nIncreases attack speed.")


func on_damage(_event: Event):
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, null, "Thunderous Roar")

	var I: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)
	var U: Unit
	var B: Buff

	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", tower, Unit.BodyPart.ORIGIN)
	Effect.destroy_effect_after_its_over(effect)

	while true:
		U = I.next()

		if U == null:
			break

		B = U.get_buff_of_type(roar_bt)

		if B != null:
			if B.user_int < 100:
				roar_bt.apply(tower, U, B.get_level() + _stats.buff_scale)
				B.user_int = B.user_int + 1
			else:
				B.refresh_duration()
		else:
			B = roar_bt.apply(tower, U, tower.get_level() * _stats.buff_scale)
			B.user_int = 0
