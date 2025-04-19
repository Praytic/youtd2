extends ItemBehavior


var charitable_bt: BuffType


func item_init():
	charitable_bt = BuffType.create_aura_effect_type("charitable_bt", true, self)
	charitable_bt.set_buff_icon("res://resources/icons/generic_icons/shiny_omega.tres")
	charitable_bt.set_buff_tooltip(tr("FCP1"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_TRIGGER_CHANCES, 0.02, 0.004)
	mod.add_modification(ModificationType.enm.MOD_MANA_PERC, 0.02, 0.004)
	mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.02, 0.004)
	charitable_bt.set_buff_modifier(mod)
