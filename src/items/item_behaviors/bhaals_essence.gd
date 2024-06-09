extends ItemBehavior


# NOTE: fixed an error in original script. Slow modifier
# wasn't added to aura effect type.

# thanks to Gex "ice core" aura
var fright_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Fright Aura - Aura[/color]\n"
	text += "Slows movement speed of enemies in 650 range by 10% and decreases their armor by 4.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% slow\n"
	text += "+0.2 armor\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.60, 0.0)


func item_init():
	fright_bt = BuffType.create_aura_effect_type("fright_bt", true, self)
	fright_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	fright_bt.set_buff_tooltip("Fright\nReduces movement speed and armor.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.10, -0.0020)
	mod.add_modification(Modification.Type.MOD_ARMOR, -4.00, -0.2)
	fright_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 650
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = fright_bt
	item.add_aura(aura)
