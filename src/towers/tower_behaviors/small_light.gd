extends TowerBehavior


# NOTE: commented out sections relevant to invisibility
# because invisible waves are currently disabled.


var holy_weak_bt: BuffType
var magical_sight_bt: BuffType


# NOTE: mod_value and mod_value_add are multiplied by 1000,
# leaving as in original
func get_tier_stats() -> Dictionary:
	return {
		1: {magical_sight_range = 650, vuln = 0.05, vuln_add = 0.002, duration = 3, duration_add = 0.12},
		2: {magical_sight_range = 700, vuln = 0.10, vuln_add = 0.004, duration = 3, duration_add = 0.16},
		3: {magical_sight_range = 750, vuln = 0.15, vuln_add = 0.006, duration = 4, duration_add = 0.16},
		4: {magical_sight_range = 800, vuln = 0.20, vuln_add = 0.008, duration = 4, duration_add = 0.20},
		5: {magical_sight_range = 850, vuln = 0.30, vuln_add = 0.010, duration = 5, duration_add = 0.20},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	# var magical_sight_range: String = Utils.format_float(_stats.magical_sight_range, 2)
	var duration: String = Utils.format_float(_stats.duration, 2)
	var duration_add: String = Utils.format_float(_stats.duration_add, 2)
	var vuln: String = Utils.format_percent(_stats.vuln, 2)
	var vuln_add: String = Utils.format_percent(_stats.vuln_add, 2)
	var undead_string: String = CreepCategory.convert_to_colored_string(CreepCategory.enm.UNDEAD)

	var list: Array[AbilityInfo] = []
	
	var power_of_light: AbilityInfo = AbilityInfo.new()
	power_of_light.name = "Power of Light"
	power_of_light.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	power_of_light.description_short = "Weakens %s hit creeps, increasing attack and spell damage taken.\n" % undead_string
	power_of_light.description_full = "Weakens %s hit creeps, increasing attack and spell damage taken by %s for %s seconds.\n" % [undead_string, vuln, duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds\n" % duration_add \
	+ "+%s damage" % vuln_add
	list.append(power_of_light)

	# var magical_sight: AbilityInfo = AbilityInfo.new()
	# magical_sight.name = "Magical Sight"
	# magical_sight.description_short = "Can see invisible enemy units.\n"
	# magical_sight.description_full = "Can see invisible enemy units in %s range.\n" % magical_sight_range
	# list.append(magical_sight)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# func load_specials(_modifier: Modifier):
# 	magical_sight_bt = MagicalSightBuff.new("magical_sight_bt", _stats.magical_sight_range, self)
# 	magical_sight_bt.apply_to_unit_permanent(tower, tower, 0)


# func get_ability_ranges() -> Array[RangeData]:
# 	return [RangeData.new("Magical Sight", _stats.magical_sight_range, TargetType.new(TargetType.CREEPS))]


func tower_init():
	var light_mod: Modifier = Modifier.new()
	holy_weak_bt = BuffType.new("holy_weak_bt", _stats.duration, _stats.duration_add, false, self)
	light_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, _stats.vuln, _stats.vuln_add)
	light_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, _stats.vuln, _stats.vuln_add)
	holy_weak_bt.set_buff_modifier(light_mod)
	holy_weak_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	holy_weak_bt.set_buff_tooltip("Holy Weakness\nIncreases attack damage taken and spell damage taken.")


func on_damage(event: Event):
	var creep: Creep = event.get_target()
	var level: int = tower.get_level()

	if creep.get_category() == CreepCategory.enm.UNDEAD:
		holy_weak_bt.apply(tower, creep, level)
