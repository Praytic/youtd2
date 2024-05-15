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
		1: {level_multiplier = 6},
		2: {level_multiplier = 9},
		3: {level_multiplier = 12},
		4: {level_multiplier = 15},
		5: {level_multiplier = 18},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var stack_bonus: String = Utils.format_percent(_stats.level_multiplier * 0.0005, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Roar"
	ability.icon = "res://Resources/Icons/animals/dragon_03.tres"
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


func tower_init():
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.05, 0.0005)

	roar_bt = BuffType.new("roar_bt", 5.0, 0.0, true, self)
	roar_bt.set_buff_icon("res://Resources/Icons/GenericIcons/wolf_howl.tres")
	roar_bt.set_buff_modifier(mod)

	roar_bt.set_buff_tooltip("Roar\nIncreases attack damage.")


func on_damage(_event: Event):
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, null, "Roar")

	var I: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 420.0)
	var U: Unit
	var B: Buff = null
	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", tower, Unit.BodyPart.ORIGIN)
	Effect.destroy_effect_after_its_over(effect)

	while true:
		U = I.next()

		if U == null:
			break

		B = U.get_buff_of_type(roar_bt)

		if B != null:
			if B.user_int < 100:
				roar_bt.apply(tower, U, B.get_level() + _stats.level_multiplier)
				B.user_int = B.user_int + 1
			else:
				B.refresh_duration()
		else:
			B = roar_bt.apply(tower, U, tower.get_level() * _stats.level_multiplier)
			B.user_int = 0
