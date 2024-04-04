extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_increase = 0.180, damage_increase_add = 0.005},
		2: {damage_increase = 0.300, damage_increase_add = 0.008},
	}


func get_ability_description() -> String:
	var damage_increase: String = Utils.format_percent(_stats.damage_increase, 2)
	var damage_increase_add: String = Utils.format_percent(_stats.damage_increase_add, 2)

	var text: String = ""

	text += "[color=GOLD]Thermal Boost - Aura[/color]\n"
	text += "Increases damage of towers in 200 range by %s.\n" % damage_increase
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % damage_increase_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Thermal Boost - Aura[/color]\n"
	text += "Increases damage of nearby towers.\n"

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 1.0 / 10000)
	aura_bt.set_buff_modifier(m)
	aura_bt.set_stacking_group("dmg_aura")
	aura_bt.set_buff_icon("angel_wings.tres")
	aura_bt.set_buff_tooltip("Thermal Boost\nIncreases attack damage.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.damage_increase * 10000)
	aura.level_add = int(_stats.damage_increase_add * 10000)
	aura.power = int(_stats.damage_increase * 10000)
	aura.power_add = int(_stats.damage_increase_add * 10000)
	aura.aura_effect = aura_bt
	return [aura]
