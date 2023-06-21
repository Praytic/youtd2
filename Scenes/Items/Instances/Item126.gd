# Forcefield Generator
extends Item


var drol_debuff_aura: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Forcefield[/color]\n"
	text += "Reduces the duration of debuffs cast on the carrier and all towers within 200 range of the carrier by 15%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-1% debuff duration\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.15, -0.01)

	drol_debuff_aura = BuffType.create_aura_effect_type("drol_debuff_aura", true, self)
	drol_debuff_aura.set_buff_icon("@@0@@")
	drol_debuff_aura.set_buff_modifier(m)
	drol_debuff_aura.set_buff_tooltip("Forcefield Effect\nThis unit's duration of debuffs is reduced.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = drol_debuff_aura
	add_aura(aura)
