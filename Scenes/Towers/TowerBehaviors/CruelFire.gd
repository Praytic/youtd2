extends TowerBehavior


var fire_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_crit = 0.050, mod_crit_add = 0.002},
		2: {mod_crit = 0.075, mod_crit_add = 0.003},
		3: {mod_crit = 0.100, mod_crit_add = 0.004},
	}


const AURA_RANGE: float = 300


func get_ability_info_list() -> Array[AbilityInfo]:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_crit: String = Utils.format_percent(_stats.mod_crit, 2)
	var mod_crit_add: String = Utils.format_percent(_stats.mod_crit_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Fire of Fury - Aura"
	ability.description_short = "Increases crit chance of nearby towers.\n"
	ability.description_full = "Increases crit chance of towers in %s range by %s.\n" % [aura_range, mod_crit] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % mod_crit_add
	list.append(ability)

	return list


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0, 1.0 / 10000)
	fire_bt = BuffType.create_aura_effect_type("fire_bt", true, self)
	fire_bt.set_buff_icon("res://Resources/Textures/GenericIcons/shiny_omega.tres")
	fire_bt.set_buff_modifier(m)
	fire_bt.set_stacking_group("fire_bt")
	fire_bt.set_buff_tooltip("Fire of Fury\nIncreases crit chance.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.mod_crit * 10000)
	aura.level_add = int(_stats.mod_crit_add * 10000)
	aura.power = int(_stats.mod_crit * 10000)
	aura.power_add = int(_stats.mod_crit_add * 10000)
	aura.aura_effect = fire_bt
	return [aura]
