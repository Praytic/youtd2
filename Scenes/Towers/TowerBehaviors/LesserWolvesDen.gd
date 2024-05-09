extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_attackspeed = 0.10, mod_attackspeed_add = 0.0050, aura_range = 200},
		2: {mod_attackspeed = 0.15, mod_attackspeed_add = 0.0075, aura_range = 250},
		3: {mod_attackspeed = 0.20, mod_attackspeed_add = 0.0100, aura_range = 300},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var aura_range: String = Utils.format_float(_stats.aura_range, 2)
	var mod_attackspeed: String = Utils.format_percent(_stats.mod_attackspeed, 2)
	var mod_attackspeed_add: String = Utils.format_percent(_stats.mod_attackspeed_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Wolven Tenacity - Aura"
	ability.icon = "res://Resources/Icons/faces/orc_01.tres"
	ability.description_short = "The strong physical presence of the wolves increases attack speed of nearby towers.\n"
	ability.description_full = "The strong physical presence of the wolves encourages nearby towers within a %s radius, to increase their attack speed by %s.\n" % [aura_range, mod_attackspeed] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack speed\n" % mod_attackspeed_add
	list.append(ability)

	return list


func tower_init():
	var m: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, 1.0 / 10000)
	aura_bt.set_buff_modifier(m)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/aries.tres")
	aura_bt.set_stacking_group("wolf_aura")
	aura_bt.set_buff_tooltip("Wolven Tenacity\nIncreases attack speed.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.mod_attackspeed * 10000)
	aura.level_add = int(_stats.mod_attackspeed_add * 10000)
	aura.power = int(_stats.mod_attackspeed * 10000)
	aura.power_add = int(_stats.mod_attackspeed_add * 10000)
	aura.aura_effect = aura_bt

	return [aura]
