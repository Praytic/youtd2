extends ItemBehavior


var divine_wings_bt: BuffType


func item_init():
	divine_wings_bt = BuffType.create_aura_effect_type("item230_divine_wings_bt", true, self)
	divine_wings_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	divine_wings_bt.set_buff_tooltip(tr("HFBQ"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.15, 0.0)
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0.0)
	divine_wings_bt.set_buff_modifier(mod)
