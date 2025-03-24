extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_movespeed = 0.15, mod_movespeed_add = 0.004},
		2: {mod_movespeed = 0.25, mod_movespeed_add = 0.006},
	}


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, -_stats.mod_movespeed_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/barefoot.tres")
	aura_bt.set_buff_tooltip(tr("BHFS"))
