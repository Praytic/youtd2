extends TowerBehavior


var aura_bt : BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_spell_crit = 0.10},
		2: {mod_spell_crit = 0.15},
		3: {mod_spell_crit = 0.20},
	}


const MOD_SPELL_CRIT_ADD: float = 0.002


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, _stats.mod_spell_crit, MOD_SPELL_CRIT_ADD)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	aura_bt.set_buff_tooltip("Ancient Magic\nIncreases spell crit chance.")
