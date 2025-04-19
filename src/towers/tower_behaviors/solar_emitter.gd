extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_armor = 10, mod_armor_add = 0.3, vuln = 0.10, vuln_add = 0.003},
		2: {aura_range = 1100, mod_armor = 15, mod_armor_add = 0.5, vuln = 0.15, vuln_add = 0.005},
	}


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ARMOR, -_stats.mod_armor, -_stats.mod_armor_add)
	mod.add_modification(ModificationType.enm.MOD_DMG_FROM_ASTRAL, _stats.vuln, _stats.vuln_add)
	mod.add_modification(ModificationType.enm.MOD_DMG_FROM_NATURE, _stats.vuln, _stats.vuln_add)
	mod.add_modification(ModificationType.enm.MOD_DMG_FROM_FIRE, _stats.vuln, _stats.vuln_add)
	mod.add_modification(ModificationType.enm.MOD_DMG_FROM_IRON, _stats.vuln, _stats.vuln_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	aura_bt.set_buff_tooltip(tr("TDD3"))
