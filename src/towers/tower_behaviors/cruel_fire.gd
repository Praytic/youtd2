extends TowerBehavior


var fire_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_crit = 0.050, mod_crit_add = 0.002},
		2: {mod_crit = 0.075, mod_crit_add = 0.003},
		3: {mod_crit = 0.100, mod_crit_add = 0.004},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, _stats.mod_crit, _stats.mod_crit_add)
	fire_bt = BuffType.create_aura_effect_type("fire_bt", true, self)
	fire_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	fire_bt.set_buff_modifier(m)
	fire_bt.set_buff_tooltip(tr("SMKF"))
