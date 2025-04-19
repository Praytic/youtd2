extends ItemBehavior


var holy_wrath_bt: BuffType


func item_init():
	holy_wrath_bt = BuffType.create_aura_effect_type("holy_wrath_bt", true, self)
	holy_wrath_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	holy_wrath_bt.set_buff_tooltip(tr("8CD3"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_UNDEAD, 0.12, 0.0024)
	holy_wrath_bt.set_buff_modifier(mod)
