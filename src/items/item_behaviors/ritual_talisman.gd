extends ItemBehavior


var ritual_bt: BuffType


func item_init():
	ritual_bt = BuffType.new("ritual_bt", 10, 0, true, self)
	ritual_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	ritual_bt.set_buff_tooltip(tr("49QO"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.2, 0.008)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.1, 0.002)
	ritual_bt.set_buff_modifier(mod)
