extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_increase = 0.180, damage_increase_add = 0.005},
		2: {damage_increase = 0.300, damage_increase_add = 0.008},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.damage_increase, _stats.damage_increase_add)
	aura_bt.set_buff_modifier(m)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/angel_outfit.tres")
	aura_bt.set_buff_tooltip(tr("LQM2"))
