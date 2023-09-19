extends Tower


var velex_dmg_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_increase = 0.180, damage_increase_add = 0.005},
		2: {damage_increase = 0.300, damage_increase_add = 0.008},
	}


func get_extra_tooltip_text() -> String:
	var damage_increase: String = Utils.format_percent(_stats.damage_increase, 2)
	var damage_increase_add: String = Utils.format_percent(_stats.damage_increase_add, 2)

	var text: String = ""

	text += "[color=GOLD]Thermal Boost - Aura[/color]\n"
	text += "Increases damage of towers in 200 range by %s.\n" % damage_increase
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % damage_increase_add

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	velex_dmg_aura = BuffType.create_aura_effect_type("velex_dmg_aura", true, self)
	m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 1.0 / 10000)
	velex_dmg_aura.set_buff_modifier(m)
	velex_dmg_aura.set_stacking_group("dmg_aura")
	velex_dmg_aura.set_buff_icon("@@0@@")
	velex_dmg_aura.set_buff_tooltip("Thermal Boost\nThis tower is affected by Thermal Boost; it will deal extra damage.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.damage_increase * 10000)
	aura.level_add = int(_stats.damage_increase_add * 10000)
	aura.power = int(_stats.damage_increase * 10000)
	aura.power_add = int(_stats.damage_increase_add * 10000)
	aura.aura_effect = velex_dmg_aura
	add_aura(aura)
