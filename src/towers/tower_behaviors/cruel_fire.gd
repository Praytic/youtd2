extends TowerBehavior


var fire_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_crit = 0.050, mod_crit_add = 0.002},
		2: {mod_crit = 0.075, mod_crit_add = 0.003},
		3: {mod_crit = 0.100, mod_crit_add = 0.004},
	}


const AURA_RANGE: float = 300


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.mod_crit, _stats.mod_crit_add)
	fire_bt = BuffType.create_aura_effect_type("fire_bt", true, self)
	fire_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	fire_bt.set_buff_modifier(m)
	fire_bt.set_buff_tooltip("Fire of Fury\nIncreases attack crit chance.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_crit: String = Utils.format_percent(_stats.mod_crit, 2)
	var mod_crit_add: String = Utils.format_percent(_stats.mod_crit_add, 2)

	aura.name = "Fire of Fury"
	aura.icon = "res://resources/icons/tower_icons/burning_watchtower.tres"
	aura.description_short = "Increases attack crit chance of nearby towers.\n"
	aura.description_full = "Increases attack crit chance of towers in %s range by %s.\n" % [aura_range, mod_crit] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % mod_crit_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = fire_bt
	
	return [aura]
