extends ItemBehavior


var flames_bt: BuffType


func item_init():
	flames_bt = BuffType.create_aura_effect_type("flames_bt", true, self)
	flames_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	flames_bt.set_buff_tooltip(tr("KT5P"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, 0.035, 0.0008)
	flames_bt.set_buff_modifier(mod)
