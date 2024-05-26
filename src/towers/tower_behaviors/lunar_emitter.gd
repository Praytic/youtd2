extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_spell_resist = 0.150, mod_spell_resist_add = 0.0045, vuln = 0.10, vuln_add = 0.003},
		2: {aura_range = 1100, mod_spell_resist = 0.225, mod_spell_resist_add = 0.0075, vuln = 0.15, vuln_add = 0.005},
	}


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({
		50: 1.0,
		350: 0.4,
		})


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


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_spell_resist: String = Utils.format_percent(_stats.mod_spell_resist, 2)
	var mod_spell_resist_add: String = Utils.format_percent(_stats.mod_spell_resist_add, 2)
	var vuln: String = Utils.format_percent(_stats.vuln, 2)
	var vuln_add: String = Utils.format_percent(_stats.vuln_add, 2)

	var astral_string: String = Element.convert_to_colored_string(Element.enm.ASTRAL)
	var darkness_string: String = Element.convert_to_colored_string(Element.enm.DARKNESS)
	var ice_string: String = Element.convert_to_colored_string(Element.enm.ICE)
	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)

	aura.name = "Moonlight"
	aura.icon = "res://resources/icons/orbs/moon.tres"
	aura.description_short = "Reduces the spell resistance of nearby enemies and increases their vulnerability to damage from %s, %s, %s and %s towers.\n" % [astral_string, darkness_string, ice_string, storm_string]
	aura.description_full = "Reduces the spell resistance of enemies in %d range by %s and increases the vulnerability to damage from %s, %s, %s and %s towers by %s.\n" % [_stats.aura_range, mod_spell_resist, astral_string, darkness_string, ice_string, storm_string, vuln] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell resistance reduction\n" % mod_spell_resist_add \
	+ "+%s vulnerability\n" % vuln_add

	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt
	return [aura]
