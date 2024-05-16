extends ItemBehavior


var motivation_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Motivation - Aura[/color]\n"
	text += "Increases attack speed of towers in 1000 range by 5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% attack speed\n"

	return text


func item_init():
	motivation_bt = BuffType.create_aura_effect_type("motivation_bt", true, self) 
	motivation_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	motivation_bt.set_buff_tooltip("Motivation\nIncreases attack speed.")
	motivation_bt.set_stacking_group("motivation_bt")
	var mod: Modifier = Modifier.new() 
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.001) 
	motivation_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 1000
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = motivation_bt
	item.add_aura(aura)
