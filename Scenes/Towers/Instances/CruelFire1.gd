extends Tower


var boekie_crit_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_crit = 0.050, mod_crit_add = 0.002},
		2: {mod_crit = 0.075, mod_crit_add = 0.003},
		3: {mod_crit = 0.100, mod_crit_add = 0.004},
	}


const AURA_RANGE: float = 300


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_crit: String = Utils.format_percent(_stats.mod_crit, 2)
	var mod_crit_add: String = Utils.format_percent(_stats.mod_crit_add, 2)

	var text: String = ""

	text += "[color=GOLD]Fire of Fury - Aura[/color]\n"
	text += "Increases crit chance of towers in %s range by %s.\n" % [aura_range, mod_crit]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % mod_crit_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Fire of Fury - Aura[/color]\n"
	text += "Increases crit chance of nearby towers.\n"

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0, 1.0 / 10000)
	boekie_crit_aura = BuffType.create_aura_effect_type("boekie_crit_aura", true, self)
	boekie_crit_aura.set_buff_icon("@@0@@")
	boekie_crit_aura.set_buff_modifier(m)
	boekie_crit_aura.set_stacking_group("crit_aura")
	boekie_crit_aura.set_buff_tooltip("Fire of Fury\nThis tower is under the effect of Fire of Fury; it has increased crit chance.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.mod_crit * 10000)
	aura.level_add = int(_stats.mod_crit_add * 10000)
	aura.power = int(_stats.mod_crit * 10000)
	aura.power_add = int(_stats.mod_crit_add * 10000)
	aura.aura_effect = boekie_crit_aura
	return [aura]
