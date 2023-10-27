# Sword of Reckoning
extends Item


var undead_aura: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Holy Wrath - Aura[/color]\n"
	text += "Grants 12% bonus damage against undead to all towers within 200 range.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% damage\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	undead_aura = BuffType.create_aura_effect_type("undead_aura", true, self)
	m.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.12, 0.0024)
	undead_aura.set_buff_modifier(m)
	undead_aura.set_stacking_group("undead_aura")
	undead_aura.set_buff_icon("@@0@@")
	undead_aura.set_buff_tooltip("Holy Wrath\nThis unit is under the effect of Holy Wrath Aura; it will deal more damage to undead units.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = undead_aura
	add_aura(aura)
