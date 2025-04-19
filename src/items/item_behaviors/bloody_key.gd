extends ItemBehavior


var bestial_bt: BuffType


func item_init():
	bestial_bt = BuffType.create_aura_effect_type("bestial_bt", true, self)
	bestial_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	bestial_bt.set_buff_tooltip(tr("UEUU"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_HUMANOID, 0.12, 0.0024)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_ORC, 0.12, 0.0024)
	mod.add_modification(ModificationType.enm.MOD_DPS_ADD, 100, 6)
	bestial_bt.set_buff_modifier(mod)
