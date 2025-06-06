extends ItemBehavior


var magnetic_bt: BuffType


func item_init():
	magnetic_bt = BuffType.create_aura_effect_type("magnetic_bt", true, self)
	magnetic_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	magnetic_bt.set_buff_tooltip(tr("C14B"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, -0.15, 0.0)
	mod.add_modification(ModificationType.enm.MOD_BUFF_DURATION, 0.1, 0.0)
	magnetic_bt.set_buff_modifier(mod)
	