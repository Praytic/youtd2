extends TowerBehavior


var rage_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {crit_chance = 0.1375, feral_dmg_gain = 0.002, feral_dmg_max = 2.00, bloodthirst_attack_speed = 1.00, bloodthirst_duration = 3, rage_buff_level_base = 0},
		2: {crit_chance = 0.1625, feral_dmg_gain = 0.003, feral_dmg_max = 2.25, bloodthirst_attack_speed = 1.25, bloodthirst_duration = 4, rage_buff_level_base = 25},
		3: {crit_chance = 0.1875, feral_dmg_gain = 0.004, feral_dmg_max = 2.50, bloodthirst_attack_speed = 1.50, bloodthirst_duration = 5, rage_buff_level_base = 50},
	}


const BLOODTHIRST_ATTACKSPEED_ADD: float = 0.01
const BLOODTHIRST_DURATION_ADD: float = 0.05


func get_ability_info_list() -> Array[AbilityInfo]:
	var feral_dmg_gain: String = Utils.format_percent(_stats.feral_dmg_gain, 2)
	var feral_dmg_max: String = Utils.format_percent(_stats.feral_dmg_max, 2)
	var bloodthirst_attack_speed: String = Utils.format_percent(_stats.bloodthirst_attack_speed, 2)
	var bloodthirst_attack_speed_add: String = Utils.format_percent(BLOODTHIRST_ATTACKSPEED_ADD, 2)
	var bloodthirst_duration: String = Utils.format_float(_stats.bloodthirst_duration, 2)
	var bloodthirst_duration_add: String = Utils.format_float(BLOODTHIRST_DURATION_ADD, 2)

	var list: Array[AbilityInfo] = []
	
	var feral_aggression: AbilityInfo = AbilityInfo.new()
	feral_aggression.name = "Feral Aggression"
	feral_aggression.icon = "res://resources/Icons/animals/rooster_warrior.tres"
	feral_aggression.description_short = "On every critical hit this tower gains permanent bonus attack damage.\n"
	feral_aggression.description_full = "On every critical hit this tower gains +%s bonus attack damage. This bonus is permanent and has a maximum of %s bonus attack damage.\n" % [feral_dmg_gain, feral_dmg_max]
	list.append(feral_aggression)

	var bloodthirst: AbilityInfo = AbilityInfo.new()
	bloodthirst.name = "Bloodthirst"
	bloodthirst.icon = "res://resources/Icons/potions/potion_red_03.tres"
	bloodthirst.description_short = "Whenever this tower kills a unit it becomes enraged.\n"
	bloodthirst.description_full = "Whenever this tower kills a unit it becomes enraged, gaining +%s attack speed for %s seconds. Cannot retrigger while active!\n" % [bloodthirst_attack_speed, bloodthirst_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s sec duration\n" % bloodthirst_duration_add \
	+ "+%s attack speed\n" % bloodthirst_attack_speed_add
	list.append(bloodthirst)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# crit chance = yes
# crit chance add = no
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.crit_chance, 0.005)


func tower_init():
	rage_bt = BuffType.new("rage_bt", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.0, BLOODTHIRST_ATTACKSPEED_ADD)
	rage_bt.set_buff_modifier(mod)
	rage_bt.set_buff_icon("res://resources/Icons/GenericIcons/mighty_force.tres")
	rage_bt.set_buff_tooltip("Enraged\nIncreases attack speed.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Damage Bonus")


func on_damage(event: Event):
	if event.is_attack_damage_critical() && tower.user_real <= _stats.feral_dmg_max:
		tower.user_real += _stats.feral_dmg_gain
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.feral_dmg_gain)


func on_kill(_event: Event):
	var lvl: int = tower.get_level()
	var buff_level: int = lvl + _stats.rage_buff_level_base
	var buff_duration: float = _stats.bloodthirst_duration + BLOODTHIRST_DURATION_ADD * lvl

	if tower.get_buff_of_type(rage_bt) == null:
		CombatLog.log_ability(tower, null, "Bloodthirst")

		rage_bt.apply_custom_timed(tower, tower, buff_level, buff_duration)


func on_create(preceding: Tower):
	if preceding != null && preceding.get_family() == tower.get_family():
		var damage_bonus: float = preceding.user_real
		tower.user_real = damage_bonus
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, damage_bonus)
	else:
		tower.user_real = 0.0


func on_tower_details() -> MultiboardValues:
	var damage_bonus: String = Utils.format_percent(tower.user_real, 1)

	multiboard.set_value(0, damage_bonus)

	return multiboard
