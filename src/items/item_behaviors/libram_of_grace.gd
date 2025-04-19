extends ItemBehavior


var grace_bt: BuffType


func item_init():
	grace_bt = BuffType.create_aura_effect_type("grace_bt", true, self)
	grace_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	grace_bt.set_buff_tooltip(tr("I4A3"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_EXP_RECEIVED, 0.1, 0.004)
	grace_bt.set_buff_modifier(mod)
