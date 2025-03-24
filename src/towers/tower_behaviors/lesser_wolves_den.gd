extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_attack_speed = 0.10, mod_attack_speed_add = 0.0050},
		2: {mod_attack_speed = 0.15, mod_attack_speed_add = 0.0075},
		3: {mod_attack_speed = 0.20, mod_attack_speed_add = 0.0100},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, _stats.mod_attack_speed, _stats.mod_attack_speed_add)
	aura_bt.set_buff_modifier(m)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/aries.tres")
	aura_bt.set_buff_tooltip(tr("GGZN"))
