extends Tower


var solar_emitter_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_armor = 10, mod_armor_add = 0.3, vuln = 0.10, vuln_add = 0.003},
		2: {aura_range = 1100, mod_armor = 15, mod_armor_add = 0.5, vuln = 0.15, vuln_add = 0.005},
	}


func get_extra_tooltip_text() -> String:
	var aura_range: String = Utils.format_float(_stats.aura_range, 2)
	var mod_armor: String = Utils.format_float(_stats.mod_armor, 2)
	var mod_armor_add: String = Utils.format_float(_stats.mod_armor_add, 2)
	var vuln: String = Utils.format_percent(_stats.vuln, 2)
	var vuln_add: String = Utils.format_percent(_stats.vuln_add, 2)

	var text: String = ""

	text += "[color=GOLD]Sunshine - Aura[/color]\n"
	text += "Reduces the armor of enemies in %s range by %s and increases the vulnerability to damage from Astral, Fire, Iron and Nature towers by %s.\n" % [aura_range, mod_armor, vuln]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s armor reduction\n" % mod_armor_add
	text += "+%s vulnerability\n" % vuln_add

	return text


func load_specials(_modifier: Modifier):
	_set_attack_style_splash({
		50: 1.0,
		350: 0.4,
		})


func tower_init():
	solar_emitter_bt = BuffType.create_aura_effect_type("solar_emitter_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.1)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_ASTRAL, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_NATURE, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, 0.0, 0.001)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_IRON, 0.0, 0.001)
	solar_emitter_bt.set_buff_modifier(mod)
	solar_emitter_bt.set_buff_icon("@@0@@")
	solar_emitter_bt.set_buff_tooltip("Sunshine Aura\nThis unit is under the effect of Sunshine Aura; it has reduced armor and takes extra damage from Astral, Fire, Iron and Nature towers.")

	var aura_level: int = int(_stats.vuln * 1000)
	var aura_level_add: int = int(_stats.vuln_add * 1000)

	var aura: AuraType = AuraType.new()
	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = solar_emitter_bt
	add_aura(aura)
