extends TowerBehavior


var speed_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_attackspeed = 0.10, mod_attackspeed_add = 0.0050, aura_range = 200},
		2: {mod_attackspeed = 0.15, mod_attackspeed_add = 0.0075, aura_range = 250},
		3: {mod_attackspeed = 0.20, mod_attackspeed_add = 0.0100, aura_range = 300},
	}


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(_stats.aura_range, 2)
	var mod_attackspeed: String = Utils.format_percent(_stats.mod_attackspeed, 2)
	var mod_attackspeed_add: String = Utils.format_percent(_stats.mod_attackspeed_add, 2)

	var text: String = ""

	text += "[color=GOLD]Wolven Tenacity - Aura[/color]\n"
	text += "The strong physical presence of the wolves encourages nearby towers within a %s radius, to increase their attack speed by %s.\n" % [aura_range, mod_attackspeed]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s attack speed\n" % mod_attackspeed_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Wolven Tenacity - Aura[/color]\n"
	text += "The strong physical presence of the wolves increases attack speed of nearby towers.\n"

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	speed_aura = BuffType.create_aura_effect_type("speed_aura", true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, 1.0 / 10000)
	speed_aura.set_buff_modifier(m)
	speed_aura.set_buff_icon("@@0@@")
	speed_aura.set_stacking_group("wolf_aura")
	speed_aura.set_buff_tooltip("Wolven Tenacity\nIncreases attack speed.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.mod_attackspeed * 10000)
	aura.level_add = int(_stats.mod_attackspeed_add * 10000)
	aura.power = int(_stats.mod_attackspeed * 10000)
	aura.power_add = int(_stats.mod_attackspeed_add * 10000)
	aura.aura_effect = speed_aura

	return [aura]
