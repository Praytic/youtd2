extends TowerBehavior


var roar_bt: BuffType

# NOTE: This is basically a magic number. Here's a table
# from original script demonstrating how it works for tier
# 2:
#
# 0.0005  0.003, 0.0045, 0.006, 0.0075, 0.009
# 0.05    0.05 , 0.05  , 0.05 , 0.05  , 0.05
#         70   , 210   , 840  , 1680  , 3360
func get_tier_stats() -> Dictionary:
	return {
		1: {mod_damage_add = 0.00, level_multiplier = 6},
		2: {mod_damage_add = 0.05, level_multiplier = 9},
		3: {mod_damage_add = 0.06, level_multiplier = 12},
		4: {mod_damage_add = 0.07, level_multiplier = 15},
		5: {mod_damage_add = 0.08, level_multiplier = 18},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var stack_bonus: String = Utils.format_percent(_stats.level_multiplier * 0.0005, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Roar"
	ability.icon = "res://resources/icons/animals/dragon_03.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance to release a [color=GOLD]Roar[/color] which increases attack damage of nearby towers.\n"
	ability.description_full = "Whenever this tower hits a creep, it has 30%% chance to release a [color=GOLD]Roar[/color]. The cry increases attack damage of all towers in 420 range by 5%% for 5 seconds. If a tower already has [color=GOLD]Roar[/color], then attack damage is increased by %s and duration is refreshed. Stacks up to 100 times.\n" % stack_bonus \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack damage\n" % stack_bonus
	ability.radius = 420
	ability.target_type = TargetType.new(TargetType.TOWERS)
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, _stats.mod_damage_add)


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.05, 0.0005)

	roar_bt = BuffType.new("roar_bt", 5.0, 0.0, true, self)
	roar_bt.set_buff_icon("res://resources/icons/generic_icons/wolf_howl.tres")
	roar_bt.set_buff_modifier(mod)

	roar_bt.set_buff_tooltip("Roar\nIncreases attack damage.")


# NOTE: need to skip stacking for buffs with stronger active
# tier. apply() will reject buffs from lower tier tower, so
# it's not possible to increase level and therefore stacks.
func on_damage(_event: Event):
	if !tower.calc_chance(0.3):
		return

	var level: int = tower.get_level()

	CombatLog.log_ability(tower, null, "Roar")

	var I: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)
	var effect: int = Effect.create_simple_at_unit_attached("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", tower, Unit.BodyPart.ORIGIN)
	Effect.destroy_effect_after_its_over(effect)

	while true:
		var target: Unit = I.next()

		if target == null:
			break

		var original_buff: Buff = target.get_buff_of_type(roar_bt)

		var original_stacks: int = 0
		var original_buff_level: int = 0
		if original_buff != null:
			original_stacks = original_buff.user_int
			original_buff_level = original_buff.get_level()

		var new_stacks: int
		var new_buff_level: int
		if original_buff == null:
			new_stacks = 1
			new_buff_level = _stats.level_multiplier * level
		else:
			if original_stacks < 100:
				new_stacks = original_stacks + 1
				new_buff_level = original_buff_level + _stats.level_multiplier
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
