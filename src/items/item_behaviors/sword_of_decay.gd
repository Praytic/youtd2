extends ItemBehavior


var rot_bt: BuffType


func item_init():
	rot_bt = BuffType.create_aura_effect_type("rot_bt", true, self)
	rot_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	rot_bt.set_buff_tooltip(tr("RI8B"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_NATURE, 0.12, 0.0024)
	rot_bt.set_buff_modifier(mod)
