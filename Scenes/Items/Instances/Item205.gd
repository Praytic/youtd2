# Sword of Decay
extends Item


var nature_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Rot - Aura[/color]\n"
	text += "Grants 12% bonus damage against nature to all towers within 200 range.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% damage\n"

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	nature_aura = BuffType.create_aura_effect_type("nature_aura", true, self)
	m.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.12, 0.0024)
	nature_aura.set_buff_modifier(m)
	nature_aura.set_stacking_group("nature_aura")
	nature_aura.set_buff_icon("@@0@@")
	nature_aura.set_buff_tooltip("Rot\nThis unit is affected by Rot; it will deal more damage to nature units.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = nature_aura
	add_aura(aura)
