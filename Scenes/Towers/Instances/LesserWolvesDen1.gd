extends Tower


var speed_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_attackspeed = 0.10, mod_attackspeed_add = 0.0050},
		2: {mod_attackspeed = 0.15, mod_attackspeed_add = 0.0075},
		3: {mod_attackspeed = 0.20, mod_attackspeed_add = 0.0100},
	}


const AURA_RANGE: float = 200


func get_extra_tooltip_text() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var mod_attack_speed: String = Utils.format_percent(_stats.mod_attackspeed, 2)
	var mod_attack_speed_add: String = Utils.format_percent(_stats.mod_attackspeed_add, 2)

	var text: String = ""

	text += "[color=GOLD]Wolven Tenacity - Aura[/color]\n"
	text += "The strong physical presence of the wolves encourages nearby towers within a %s radius, to increase their attack speed by %s.\n" % [aura_range, mod_attack_speed]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s attack speed\n" % mod_attack_speed_add

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	speed_aura = BuffType.create_aura_effect_type("speed_aura", true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0, 1.0 / 10000)
	speed_aura.set_buff_modifier(m)
	speed_aura.set_buff_icon("@@0@@")
	speed_aura.set_stacking_group("wolf_aura")
	speed_aura.set_buff_tooltip("Wolven Tenacity\nThis tower is under the effect of Wolven Tenacity; it has increased attack speed.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.mod_attackspeed * 10000)
	aura.level_add = int(_stats.mod_attackspeed_add * 10000)
	aura.power = int(_stats.mod_attackspeed * 10000)
	aura.power_add = int(_stats.mod_attackspeed_add * 10000)
	aura.aura_effect = speed_aura
	add_aura(aura)
