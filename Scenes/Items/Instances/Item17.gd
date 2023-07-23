# Cruel Torch
extends Item


var boekie_crit_aura2: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Flames of Fury - Aura[/color]\n"
	text += "Increases crit chance of towers in 300 range by 3.5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% chance\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	boekie_crit_aura2 = BuffType.create_aura_effect_type("boekie_crit_aura2", true, self)
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.035, 0.0)
	boekie_crit_aura2.set_buff_icon("@@0@@")
	boekie_crit_aura2.set_buff_modifier(m)
	boekie_crit_aura2.set_buff_tooltip("Flames of Fury\nThis unit is under the effect of Flames of Fury Aura; it has increased critical chance.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = boekie_crit_aura2
	add_aura(aura)
