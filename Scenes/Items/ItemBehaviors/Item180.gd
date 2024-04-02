# Libram of Grace
extends ItemBehavior


var drol_libram: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Grace - Aura[/color]\n"
	text += "Increases the amount of experience towers in 150 range of the carrier gain by 10%.\n"
	text += " \n"
	text += "Level Bonus:\n"
	text += "+0.4% experience\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.1, 0.004)
	drol_libram = BuffType.create_aura_effect_type("drol_libram", true, self)
	drol_libram.set_buff_modifier(m)
	drol_libram.set_buff_icon("winged_man.tres")
	drol_libram.set_buff_tooltip("Grace\nIncreases experience received.")

	var aura: AuraType = AuraType.new()
	aura.power_add = 1
	aura.level_add = 1
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.level = 0
	aura.aura_effect = drol_libram
	aura.power = 0
	aura.target_self = true
	aura.aura_range = 150

	item.add_aura(aura)
