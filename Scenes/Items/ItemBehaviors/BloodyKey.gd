extends ItemBehavior


var bestial_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Bestial Rage - Aura[/color]\n"
	text += "Grants 12% bonus damage against orc and humanoid creeps and also increases dps by 100 for all towers in 200 AoE.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.24% to orcs and humanoids\n"
	text += "+6 dps\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.70, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, -0.70, 0.0)


func item_init():
	bestial_bt = BuffType.create_aura_effect_type("bestial_bt", true, self)
	bestial_bt.set_buff_icon("res://Resources/Textures/GenericIcons/mighty_force.tres")
	bestial_bt.set_buff_tooltip("Bestial Rage\nIncreases damage dealt to orc and human creeps. Also increases DPS.")
	bestial_bt.set_stacking_group("bestial_bt")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.12, 0.0024)
	mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.12, 0.0024)
	mod.add_modification(Modification.Type.MOD_DPS_ADD, 100, 6)
	bestial_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = bestial_bt
	item.add_aura(aura)
