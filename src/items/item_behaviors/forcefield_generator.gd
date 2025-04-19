extends ItemBehavior


var forcefield_bt: BuffType


func item_init():
	forcefield_bt = BuffType.create_aura_effect_type("forcefield_bt", true, self)
	forcefield_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	forcefield_bt.set_buff_tooltip(tr("X440"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, -0.15, -0.01)
	forcefield_bt.set_buff_modifier(mod)
