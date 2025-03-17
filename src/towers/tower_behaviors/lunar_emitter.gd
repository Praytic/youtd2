extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_spell_resist = 0.150, mod_spell_resist_add = 0.0045, vuln = 0.10, vuln_add = 0.003},
		2: {aura_range = 1100, mod_spell_resist = 0.225, mod_spell_resist_add = 0.0075, vuln = 0.15, vuln_add = 0.005},
	}


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, _stats.mod_spell_resist, _stats.mod_spell_resist_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_ASTRAL, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_DARKNESS, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_ICE, _stats.vuln, _stats.vuln_add)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, _stats.vuln, _stats.vuln_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	aura_bt.set_buff_tooltip("Moonlight Aura\nIncreases spell damage taken and damage taken from Astral, Darkness, Ice and Storm towers.")
