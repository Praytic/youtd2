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


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var attack_speed: String = Utils.format_percent(_stats.buff_scale * 0.0005, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Thunderous Roar"
	ability.icon = "res://resources/icons/animals/dragon_03.tres"
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
	roar_bt.set_buff_icon("res://resources/icons/generic_icons/wolf_howl.tres")
	roar_bt.set_buff_modifier(mod)
	roar_bt.set_buff_tooltip("Thunderous Roar\nIncreases attack speed.")


# NOTE: need to skip stacking for buffs with higher active
# tier. apply() will reject buffs from lower tier tower, so
# it's not possible to increase level and therefore stacks.
func on_damage(_event: Event):
	if !tower.calc_chance(0.3):
		return
	
	var level: int = tower.get_level()

	CombatLog.log_ability(tower, null, "Thunderous Roar")
	
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)

	Effect.create_simple_at_unit_attached("res://src/effects/roar.tscn", tower, Unit.BodyPart.ORIGIN)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		var original_buff: Buff = target.get_buff_of_type(roar_bt)

		var tier_is_weaker_than_active: bool = original_buff != null && tower.get_tier() < original_buff.get_tower_tier()
		if tier_is_weaker_than_active:
			continue

		var original_stacks: int = 0
		var original_buff_level: int = 0
		if original_buff != null:
			original_stacks = original_buff.user_int
			original_buff_level = original_buff.get_level()

		var new_stacks: int
		var new_buff_level: int
		if original_buff == null:
			new_stacks = 1
			new_buff_level = _stats.buff_scale * level
		else:
			if original_stacks < 100:
				new_stacks = original_stacks + 1
				new_buff_level = original_buff_level + _stats.buff_scale
			else:
				new_stacks = original_stacks
				new_buff_level = original_buff_level

		var new_buff: Buff = roar_bt.apply(tower, target, new_buff_level)

#		NOTE: need to check for this condition because
#		apply() can reject reapply if this tower has lower
#		tier than the original buff caster. In that case,
#		lower tier tower can't increase level of buff -
#		therefore can't increase stacks.
		var was_able_to_increase_stacks: bool = new_buff.get_level() == new_buff_level
		if was_able_to_increase_stacks:
			new_buff.user_int = new_stacks
			new_buff.set_displayed_stacks(new_stacks)
